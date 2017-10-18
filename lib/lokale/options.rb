
require "optparse"



  Action = Struct.new("Action", :type, :arg, :precedence)

  class Settings
    attr_reader :actions

    def self.get 
      actions = []

      OptionParser.new do |opts|
        opts.banner = "Usage: lokale [-bsh]"

        opts.on("-b", "--copy-base", "Copies 'en' localization files to 'Base'") do |n|
          actions << Action.new(:copy_base, nil, 10)
        end

        opts.on("-s", "--summary", "Prints project summary") do |n|
          actions << Action.new(:summary, nil, 100)
        end

        opts.on("-h", "--help", "Prints this help") do
          puts opts
          exit
        end
      end.parse!

      if actions.empty? 
        actions.sort_by! { |e| e.precedence }
      else 
        actions.sort_by! { |e| e.precedence }
      end

      Settings.new(actions)
    end

    def initialize(actions)
      @actions = actions
    end
  end



