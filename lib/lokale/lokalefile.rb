
require "lokale/config"
require "lokale/model"

DEFAULT_LOKALEFILE = <<FILE

add_macro "NSLocalizedString" do |m|
  m.localization_file = "Localizable.strings"

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


class Config 
  def read_lokalefile(project_path)
    lokalefile_path = File.join(project_path, ".lokale")

    if File.file? lokalefile_path 
      read_config_from_file(lokalefile_path)
    else
      default_config
    end
  end

  def default_config
    read_config_from_file(nil, DEFAULT_LOKALEFILE)
  end

  def read_config_from_file(file_path, content=nil)
    content ||= File.read(file_path)
    reset_config
    instance_eval(content)
  end
end


class Config 

  attr_reader :macros
  attr_reader :main_lang, :base_lang

  def reset_config 
    @macros = nil
    @main_lang = nil
    @base_lang = nil  
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


def test 
  Config.get.read_lokalefile File.dirname(__FILE__)
  p Config.get.macros
  p Config.get.main_lang
  p Config.get.base_lang
end

# test

