require "lokale/version"
require "lokale/colorize"
require "lokale/util"
require "set"

module Lokale 

  class String
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


  class LString
    attr_accessor :key, :str, :note, :target

    def initialize(key, str, note, target)
      @key = key; @str = str; @note = note; @target = target
    end

    def self.strings_from_file(file_path, lang)
      regex = /(?:\/* (.+) *\/.*\n)?"(.+)" *= *"(.+)";/
      File.read(file_path).scan(regex).map { |m| LString.new(m[1], m[2], m[0], lang) }
    end
  end

  #

  class LFile
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
      LFile.new(file_path)
    end

    def inspect 
      "<#{@lang}/#{full_name}>"
    end

    def full_name
      "#{@name}.#{@type}"
    end

    def strings_file?
      @type == "strings" || @type == "stringsdict"
    end

    def parsed
      return @parsed unless @parsed.nil?
      @parsed = case type
        when "strings"      then LString.strings_from_file(@path, @lang)
        when "stringsdict"  then []
        else nil
      end      
    end

    def repeats
      return [] if @parsed.nil?
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
    attr_reader :regex, :found_strings, :name, :file_name

    def initialize(name, regex, file_name)
      @name = name
      @regex = regex
      @file_name = file_name
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
end



module Lokale 
  class Agent
    attr_reader :proj_path, :macros, :lfiles, :sfiles_proceeded

    def initialize(proj_path, macros)
      @proj_path = proj_path
      @macros = macros

      get_localization_files
      find_all_localization_calls
    end

    ###

    def proj_files 
      if block_given?
        Dir.glob("#{@proj_path}/**/**") { |f| yield f }
      else
        Dir.glob("#{@proj_path}/**/**")
      end
    end

    def get_localization_files
      return @lfiles unless @lfiles.nil?
      @lfiles = proj_files.map { |file| LFile.try_to_read(file) }.compact
    end

    def find_all_localization_calls
      @macros.each { |m| m.clear_calls }

      @sfiles_proceeded = 0
      proj_files do |file| 
        next unless file.source_file?        

        file_content = File.read(file)
        @macros.each { |macro| macro.read_from file_content }
        @sfiles_proceeded += 1
      end
    end

    ###

    def copy_base
      en_files = @lfiles.group_by { |f| f.lang }["en"].select { |f| f.strings_file? }
      base_files = @lfiles.group_by { |f| f.lang }["Base"].select { |f| f.strings_file? }

      en_files.each do |en|
        base = base_files.select { |f| f.full_name == en.full_name }.sample
        next if base.nil?
        IO.copy_stream(en.path, base.path)
      end
    end

    def append_new_macro_calls

    end
  end
end

