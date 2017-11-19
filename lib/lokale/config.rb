
require "optparse"
require "lokale/util"

module Lokale
  class Action
    attr_accessor :type, :arg

    def initialize(type)
      @type = type
    end

    def self.summary;          Action.new(:summary)         end
    def self.copy_base;        Action.new(:copy_base)       end
    def self.append;           Action.new(:append)          end  
    def self.export;           Action.new(:export)          end  
    def self.import;           Action.new(:import)          end  
    def self.create_config;    Action.new(:create_config)   end  
  end

  class Config
    attr_accessor :actions
    attr_accessor :project_path, :project_name

    def self.init 
      return unless @config.nil?

      actions = []

      OptionParser.new do |opts|
        opts.banner = "Usage: lokale [-bsh]"

        opts.on("-b", "--copy-base", "Copies 'en' localization files to 'Base'") do |n|
          actions << Action.copy_base
        end

        opts.on("-s", "--summary", "Prints project summary") do |n|
          actions << Action.summary
        end

        opts.on("-a", "--append", "Appends new strings to english localization file") do |n|
          actions << Action.append
        end

        opts.on("-e", "--export", "Creates xliff files with missing localization") do |n|
          actions << Action.export
        end

        opts.on("-i", "--import", "Looks for xliffs in project dir and imports whatever possible") do |n|
          actions << Action.import
        end

        opts.on("-f", "--create-config-file", "Create default `.lokale` config file") do |n|
          actions << Action.create_config
        end

        opts.on("-h", "--help", "Prints this help") do
          puts opts
          exit
        end
      end.parse!

      actions << Action.summary if actions.empty? 

      @config = Config.new
      @config.actions = actions
    end

    def self.get
      init if @config.nil?
      @config
    end
  end
end


