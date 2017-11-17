
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


module Lokale
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
  end

  #

  class Macro
    attr_reader :regex, :found_strings, :name, :file_name

    def initialize(name)
      @name = name
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
