
require "lokale/config"
require "lokale/model"

module Lokale
  DEFAULT_LOKALEFILE = <<FILE

add_macro "NSLocalizedString" do |m|
  m.localization_file = "Localizable.strings"
  m.project_file = "Strings.swift"

  m.regex = /NSLocalizedString\\("(.+?)",\\s*comment:\\s*"(.*?)"\\)/
  m.key_index = 0
  m.note_index = 1
end

add_macro "PluralString" do |m|
  m.regex = /String.localizedPlural\\("(.+?)"/
  m.key_index = 0
end

main_language "en"
base_language "Base"

FILE
end

module Lokale
  class Config 
    def read_lokalefile
      if File.file? lokalefile_path 
        read_config_from_file(lokalefile_path)
      else
        read_default_config
      end
    end

    def read_default_config
      reset_config
      instance_eval(DEFAULT_LOKALEFILE)
    end

    def read_config_from_file(file_path)
      content = File.read(file_path)
      reset_config
      instance_eval(content)
      fill_defaults
    end

    def create_default_file
      if File.file? lokalefile_path 
        puts "Config file `#{lokalefile_path.blue}` already exists."
      else
        File.write(lokalefile_path, DEFAULT_LOKALEFILE)
        puts "Created config file at `#{lokalefile_path.blue}`"
      end
      
    end

    def lokalefile_path
      File.join(@project_path, ".lokale") 
    end



    attr_reader :macros
    attr_reader :main_lang, :base_lang

    def reset_config 
      @macros = nil
      @main_lang = nil
      @base_lang = nil  
    end

    def fill_defaults
      default = Config.new
      default.read_default_config

      @macros ||= default.macros
      @main_lang ||= default.main_lang
      @base_lang ||= default.base_lang
    end

    private

    def add_macro(name)
      macro = Lokale::Macro.new(name)
      yield macro
      @macros ||= []
      @macros << macro
    end
    
    def main_language(l)
      @main_lang = l
    end

    def base_language(l)
      @base_lang = l
    end
  end
end

