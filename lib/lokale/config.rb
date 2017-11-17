
require "optparse"
require "lokale/util"

class Action
  attr_accessor :type, :arg, :precedence

  include Then

  def self.summary
    Action.new.then do |a|
      a.type = :summary
      a.precedence = 10
    end
  end

  def self.copy_base
    Action.new.then do |a|
      a.type = :copy_base
      a.precedence = 50
    end
  end

  def self.append
    Action.new.then do |a|
      a.type = :append
      a.precedence = 60
    end
  end
end

class Config
  attr_accessor :actions

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

    @config = Config.new
    @config.actions = actions
  end

  def self.get
    init if @config.nil?
    @config
  end
end


