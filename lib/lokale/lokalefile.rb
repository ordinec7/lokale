
require "lokale/config"
require "lokale/model"

class Config 
  def read_lokalefile(project_path)
    lokalefile_path = File.join(project_path, ".lokale")
    if File.file? lokalefile_path 
      config_from_file(lokalefile_path)
    else
      default_config
    end
  end

  def default_config

  end

  def config_from_file(file_path, content=nil)
    content ||= File.read(file_path)
    p content
    instance_eval(content)
  end
end


class Config 

  attr_reader :macros

  def add_macro(name)
    p name
    macro = Lokale::Macro.new()
    yield macro
    @macros ||= []
    @macros << macro
  end
end


def test 
  Config.get.read_lokalefile File.dirname(__FILE__)

end

test
