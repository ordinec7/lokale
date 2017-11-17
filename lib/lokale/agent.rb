require "lokale/version"
require "lokale/colorize"
require "lokale/util"
require "lokale/model"
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

