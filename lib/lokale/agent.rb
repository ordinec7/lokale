require "lokale/version"
require "lokale/colorize"
require "lokale/util"
require "lokale/model"
require "xliffle"
require "set"


module Lokale
  class LFile
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

  class LString
    def write_format
      "/* #{note} */\n\"#{key}\" = \"#{str}\";\n"
    end

    def pretty
      "\"#{key}\" = \"#{str}\";"
    end

    attr_accessor :source

    def for_export(lang)
      str = LString.new(@key, nil, @note, lang)
      str.source = @str
      str
    end
  end
end



module Lokale 
  class Agent
    attr_reader :proj_path, :macros, :lfiles, :sfiles_proceeded

    def initialize(proj_path, macros)
      @proj_path = proj_path
      @macros = macros

      @writer = Writer.new
      @exporter = Exporter.new
      @importer = Importer.new

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
      main_lfiles = @lfiles.group_by { |f| f.lang }[Config.get.main_lang].select { |f| f.strings_file? }
      base_lfiles = @lfiles.group_by { |f| f.lang }[Config.get.base_lang].select { |f| f.strings_file? }

      main_lfiles.each do |en|
        base = base_lfiles.select { |f| f.full_name == en.full_name }.sample
        next if base.nil?
        IO.copy_stream(en.path, base.path)
      end
    end

    def append_new_macro_calls
      @macros.each do |macro|
        next if macro.localization_file.nil?
        file = @lfiles.select { |lf| lf.full_name == macro.localization_file && lf.lang == Config.get.main_lang }.sample
        next if file.nil?

        found_strings = macro.found_strings.keys
        proj_keys = found_strings.map { |ls| ls.key }.to_set
        current_keys = file.keys.to_set
        new_keys = proj_keys - current_keys

        next if new_keys.empty?

        new_lstrings = found_strings.select { |ls| new_keys.include? ls.key }
        @writer.append_new_strings(new_lstrings, file)
      end
    end

    def export_xliffs
      files = Config.get.base_lang.nil? ? @lfiles : @lfiles.select { |lf| lf.lang != Config.get.base_lang }
      main_lang = Config.get.main_lang
      diffs = Exporter::Diff.find(files, main_lang)
      @exporter.export(diffs) unless diffs.empty?
    end

    def try_to_import
    end
  end

  class Writer 
    def find_append_point(content)
      ignore_after = content =~ /^\s*?\/\/\s*?\n\s*?\/\/\s*?MARK/
      string_regexp = /".*?"\s*=\s*".*?"\s*;\s*\n/

      append_at = content.match(string_regexp).end(0) - 1
      return if append_at.nil?
      next_try = append_at
      while next_try < ignore_after
        append_at = next_try
        next_try = content.match(string_regexp, next_try).end(0) - 1
      end

      append_at - 1
    end

    def append_new_strings(lstrings, file)
      content = file.content

      puts "Appending #{lstrings.size} new strings to file #{file.lang}/#{file.full_name}".blue
      lstrings.each { |ls| puts ls.pretty }
      puts

      append_at = find_append_point(content)
      data_to_append = "\n" + lstrings.map { |ls| ls.write_format }.join("\n")

      content.insert(append_at, data_to_append)
      File.write(file.path, content)
    end
  end


  class Exporter
    class Diff
      attr_reader :lang, :missing_strings

      def self.find(files, main_lang)
        groups = files.group_by { |lf| lf.lang }
        main_files = groups[main_lang]
        diffs = []
        groups.each do |lang, files|
          next if lang == main_lang
          diffs << Diff.new(main_files, files, lang)
        end
        diffs.delete_if { |d| d.empty? }
      end

      def initialize(main_files, lfiles, lang)
        @lang = lang
        @missing_strings = Hash.new { |h, k| h[k] = [] }
        lfiles.each do |lf|
          next unless lf.strings_file?
          counterpart = main_files.select { |m| m.full_name == lf.full_name }.sample
          next if counterpart.nil?

          missing_keys = counterpart.keys - lf.keys
          next if missing_keys.empty?

          counterpart.parsed.each do |lstr|
            next unless missing_keys.include? lstr.key 
            @missing_strings[lf.full_name] << lstr.for_export(lang)
          end
        end
      end

      def empty?
        @missing_strings.empty? || @missing_strings.all? { |file_name, strings| strings.empty? }
      end
    end


    def export(diffs)
      # puts "Exporting stuff"
      diffs.each do |d|
        puts "Writing xliff for `#{d.lang}` language. Missing strings count: #{d.missing_strings.values.map { |e| e.size }.reduce(:+)}"

        xliffle = Xliffle.new
        d.missing_strings.each do |lfile, strings|
          xfile = xliffle.file(lfile, Config.get.main_lang, d.lang)
          strings.each do |lstr|
            xfile.string(lstr.key, lstr.source, nil).note(lstr.note, 0)
          end
        end

        file_name = "#{d.lang}.xliff"
        File.write(file_name, xliffle.to_xliff)
      end
    end
  end

  class Importer
    def look_for_strings(root_path)
    end
  end
end

