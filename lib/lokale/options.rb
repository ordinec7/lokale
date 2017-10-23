
require "optparse"

class Action
  attr_reader :type, :arg, :precedence
  def initialize(type, arg, precedence)
    @type = type; @arg = arg; @precedence = precedence
  end

  def self.summary
    Action.new(:summary, nil, 10)
  end
  def self.copy_base
    Action.new(:copy_base, nil, 50)
  end
  def self.append
    Action.new(:append, nil, 60)
  end
end

class Settings
  attr_reader :actions

  def self.init 
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

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
      end
    end.parse!



    if actions.empty? 
      actions << Action.summary
    else 
      actions.sort_by! { |e| -e.precedence }
    end

    @shared_settings = Settings.new(actions)
  end

  def self.get
    init if @shared_settings.nil?
    @shared_settings
  end

  def initialize(actions)
    @actions = actions
  end
end



