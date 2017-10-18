# require "lokale/version"
require "set"

class String
  def rpadded(count=20)
    "%-#{count}.#{count}s" % self
  end

  def lpadded(count=20)
    "%#{count}.#{count}s" % self
  end

  def localization_file?
    File.directory?(self) == false &&
        (self =~ /\/Pods\//) == nil &&
        (self =~ /\.bundle\//) == nil &&
        (self =~ /\/(.{1,8})\.lproj\//)
  end

  def source_file?
    (File.directory?(self) == false) && (self =~ /\/Pods\//).nil? && ((self =~ /\.(swift|h|m)$/) != nil)
  end
end

module Lokale 

  class LocalizedString    
    attr_accessor :key, :str, :note, :target

    def initialize(key, str, note, target)
      @key = key; @str = str; @note = note; @target = target
    end

    def self.strings_from_file(file_path, lang)
      regex = /(?:\/* (.+) *\/.*\n)?"(.+)" *= *"(.+)";/
      File.read(file_path).scan(regex).map { |m| LocalizedString.new(m[1], m[2], m[0], lang) }
    end
  end

  #

  class LocalizationFile
    attr_reader :path, :lang, :name, :type
    def initialize(file_path)
      @path = file_path

      File.basename(file_path) =~ /^(.+)\.([^\.]*?)$/
      @name = $1
      @type = $2

      file_path =~ /\/(.{1,8})\.lproj\//
      @lang = $1
    end

    def self.try_to_read(file_path)
      return nil unless file_path.localization_file?
      LocalizationFile.new(file_path)
    end

    def inspect 
      "<#{@lang}/#{full_name}>"
    end

    def full_name
      "#{@name}.#{@type}"
    end

    def parsed
      return @parsed unless @parsed.nil?
      @parsed = case type
        when "strings"      then LocalizedString.strings_from_file(@path, @lang)
        when "stringsdict"  then []
        else nil
      end      
    end

    def repeats
      return [] if @parsed.nil?
      keys = @parsed.map(&:key)
      uniq_keys = keys.to_set

      keys.delete_if do |k|
        if uniq_keys.include? k
          uniq_keys.delete k
          true
        end
      end
    end

    def keys 
      return nil if parsed.nil?
      parsed.map(&:key)
    end
  end

  #

  class Macro
    attr_reader :regex, :found_strings, :name

    def initialize(name, regex)
      @name = name
      @regex = regex
      clear_calls
    end 

    def clear_calls
      @found_strings = Hash.new { |h, k| h[k] = 0 }
    end

    def read_from(file)
      file.scan(@regex) { |m| @found_strings[m] += 1 }
    end

    def uniq_count
      @found_strings.size
    end

    def total_count
      @found_strings.values.reduce(:+) || 0
    end
  end


  #
  #
  #
  #

  class Agent
    attr_reader :proj_path, :macros, :lfiles, :sfiles_proceeded

    def initialize(proj_path, macros)
      @proj_path = proj_path
      @macros = macros

      get_localization_files
      find_all_localization_calls
    end

    def proj_files 
      Dir.glob("#{@proj_path}/**/**")
    end

    def get_localization_files
      return @lfiles unless @lfiles.nil?
      @lfiles = proj_files.map { |file| LocalizationFile.try_to_read(file) }.compact
    end

    def find_all_localization_calls
      @macros.each { |m| m.clear_calls }

      @sfiles_proceeded = 0
      proj_files.each do |file| 
        next unless file.source_file?        

        file_content = File.read(file)
        @macros.each { |macro| macro.read_from file_content }
        @sfiles_proceeded += 1
      end
    end
  end

  #

  class Reporter
    def initialize(agent)
      @agent = agent
    end

    def print_summary
      print_macro_calls_summary
      print_macro_table
      print_files_table
      print_repeats_report
      print_diferences_report
    end 

    def print_macro_calls_summary
      total_macro_calls = @agent.macros.map(&:total_count).reduce(:+)
      uniq_macro_calls = @agent.macros.map(&:uniq_count).reduce(:+)
      puts "Found #{total_macro_calls} localization macro calls in #{@agent.sfiles_proceeded} files."
      puts "Uniq macro calls: #{uniq_macro_calls}"
      puts
    end


    def print_files_table
      languages = @agent.lfiles.map { |e| e.lang }.to_set.to_a
      files = @agent.lfiles.map { |e| e.full_name }.to_set.to_a

      puts "Found #{@agent.lfiles.size} localized files for #{languages.size} languages."

      description_header = "[*]".rpadded(36)
      languages.each { |l| description_header << l.rpadded(8) }
      puts description_header

      files.each do |f|
        description_string = f.rpadded(36)
        languages.each do |l|
          lfile = @agent.lfiles.select { |lf| lf.full_name == f && lf.lang == l }
          description_string << (lfile.empty? ? "-" : lfile[0].parsed.nil? ? "*" : "#{lfile[0].parsed.size}").rpadded(8)
        end
        puts description_string
      end
      puts
    end

    def print_macro_table
      @agent.macros.each do |macro|
        puts "#{macro.name}:".rpadded(24) + "total: #{macro.total_count}".rpadded(16) + "uniq: #{macro.uniq_count}"
      end
      puts
    end

    def print_repeats_report
      repeats_repot = ""
      @agent.lfiles.each do |lf| 
        repeats = lf.repeats
        next if repeats.count.zero?
        repeats_repot << "#{lf.lang}/#{lf.full_name} repeats:\n"
        repeats_repot << repeats.join("\n")
        repeats_repot << "\n"
      end

      if repeats_repot.empty? 
        puts "Repeats not found."
        puts
      else
        puts repeats_repot
        puts
      end
    end

    def print_diferences_report
      diferences_repot = ""

      @agent.lfiles.group_by { |f| f.full_name }.each do |file_name, files|
        base_lang = files.select { |f| f.lang == "Base" }.first.nil? ? "en" : "Base"
        files = files.select { |f| f.lang != base_lang }
        all_keys = files.map(&:keys).compact.map(&:to_set)
        next if all_keys.empty?
        shared_keys = all_keys.reduce(:&)
        all_keys.map! { |ks| ks - shared_keys }
        next if all_keys.map(&:length).reduce(:+).zero?

        diferences_repot << "Excess keys in file \"#{file_name}\":\n"
        all_keys.zip(files) do |excess_keys, lfile|
          next if excess_keys.size.zero?
          diferences_repot << "* #{lfile.lang}: #{excess_keys.size} key(s).\n"
          excess_keys.each { |k| diferences_repot << "#{k}\n" }
        end
        diferences_repot << "\n"
      end

      if diferences_repot.empty? 
        puts "Localization files are full."
        puts
      else
        puts "Localization files are not full."
        puts
        puts diferences_repot
        puts
      end
    end 
  end
end



# macros = [
#     Lokale::Macro.new("NSLocalizedString", /NSLocalizedString\("(.+?)",\s*comment:\s*"(.*?)"\)/), 
#     Lokale::Macro.new("PluralString", /String.localizedPlural\("(.+?)"/),
#     #LocalizationMacro.new("ObjC String", /NSLocalizedString\("(.*)",\s*(.*)\)/),
#     #LocalizationMacro.new("ObjC Table String", /NSLocalizedStringFromTableInBundle\((.*?),/)
# ]

# agent = Lokale::Agent.new("/Users/crysberry/Documents/hand2hand", macros)
# reporter = Lokale::Reporter.new(agent)
# reporter.print_summary
