
require 'lokale/find_dir'
require 'lokale/colorize'
require 'lokale/config'
require 'lokale/reporter'
require 'lokale/lokalefile'
require 'lokale/agent'

module Lokale
  class Action
    def print(str)
      puts str.blue
    end

    def perform(agent, reporter)
      send(("perform_" + @type.to_s).to_sym, agent, reporter)
    end

    def perform_summary(agent, reporter)
      print "Printing summary...".blue
      reporter.print_summary
    end

    def perform_copy_base(agent, reporter)
      print "Copying `en` strings files to `Base`...".blue
      agent.copy_base
    end

    def perform_append(agent, reporter)
      print "Appending new macro calls to localization files...".blue
      agent.append_new_macro_calls
    end

    def perform_export(agent, reporter)
      print "Preparing xliff files with new localized strings...".blue
      agent.export_xliffs
    end

    def perform_import(agent, reporter)
      print "Attempting to import new strings...".blue
      agent.try_to_import
    end

    def perform_create_config(agent, reporter)
      print "Creating config file...".blue
      Config.get.create_default_file
    end
  end
end


module Lokale
  class Main

    def run
      find_dir
      read_config
      init_workers
      run_actions
    end

    #

    def find_dir 
      begin
        @project_path, @project_name = ProjectFinder::find_proj   
      rescue Exception => e
        puts e
        exit
      end

      puts "Target Xcode project: '#{@project_name}'".green
    end

    def read_config
      Config.init
      Config.get.project_path = @project_path
      Config.get.project_name = @project_name

      begin
        Config.get.read_lokalefile
      rescue Exception => e
        puts "Error reading config file".red
        puts e
        exit
      end
    end

    def init_workers
      @agent = Lokale::Agent.new(@project_path, Config.get.macros)
      @reporter = Lokale::Reporter.new(@agent)
    end
    
    def run_actions
      Config.get.actions.each { |action| action.perform(@agent, @reporter) }
    end
  end
end


