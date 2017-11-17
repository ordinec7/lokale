
require 'lokale/find_dir'
require 'lokale/colorize'
require 'lokale/config'
require 'lokale/reporter'
require 'lokale/lokalefile'

class Action
  def print(str)
    puts str.blue
  end

  def perform(agent, reporter)
    send(("perform_" + @type.to_s).to_sym, agent, reporter)
  end

  def perform_summary(agent, reporter)
    print "Printing summary".blue
    reporter.print_summary
  end

  def perform_copy_base(agent, reporter)
    print "Copying `en` strings files to `Base`".blue
    agent.copy_base
  end

  def perform_append(agent, reporter)

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

      puts "Target Xcode project: '#{project_name}'".green
    end

    def read_config
      Config.init
      Config.get.read_lokalefile(@project_path)
    end

    def init_workers
      @agent = Lokale::Agent.new(project_path, macros)
      @reporter = Lokale::Reporter.new(agent)
    end
    
    def run_actions
      Config.get.actions.each { |action| action.perform(agent, reporter) }
    end
  end
end


