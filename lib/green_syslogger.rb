require 'syslog'

#
# Custom log
#
# To install it cofigure it on the <RAILS_ENVIRONMENT>.rb:
#    config.logger = GreenSyslogger.new(<default tag>, <facility>, <level>)
#
# By default
#     GreenSyslogger.new('rails', 'local2', :debug)
#
# To use it: 
#
#    logger.debug("my debug message")
#    logger.error("my error message")
#
# To user another tag:
#
#    logger.custom("my custom message", <tag>, <level>)
#
# By default:
#
#    logger.custom("my custom message", 'custom', :info)
#
class GreenSyslogger
  attr_accessor :level
  
  # Mapping between Logger levels and Syslog levels
  LEVELS_MAP = {
    :debug    => [:debug    , 0],
    :info     => [:info     , 1],
    :warn     => [:warning  , 2],
    :error    => [:err      , 3],
    :fatal    => [:emerg    , 4],
    :unknown  => [:debub    , 5]
  }
  
  DEFAULT_CONF  = [ Syslog::LOG_PID, Syslog::LOG_LOCAL2 ]
  
  def initialize(tag = 'rails', facility = 'local2', level = :debug)
    @tag = tag
    @facility = facility
    @level = level
    @syslog = Syslog.open( @tag, Syslog::LOG_PID, Syslog.const_get( "LOG_#{@facility.upcase}" ) )
  end
  
  def close
    @syslog.close
  end
  
  def opened?
    @syslog.opened?
  end

  # level default to 'info'
  # tag default 'ids-custom'
  def custom(message, tag = 'custom', level = :info)
    @syslog = Syslog.reopen( tag, Syslog::LOG_PID, Syslog.const_get( "LOG_#{@facility.upcase}" ) )
    self.log(message, level)
    @syslog = Syslog.reopen( @tag, Syslog::LOG_PID, Syslog.const_get( "LOG_#{@facility.upcase}" ) )
  end
  
  # level default to 'info'
  def log(message, level = :info)
    # File.open("/tmp/ids.log", 'w') { |f| f.write(message) }
    @syslog.send( LEVELS_MAP[level][0], clean( message ) )
  end
  
  LEVELS_MAP.each_key do |level|
    define_method level do |message|
      if self.send("#{level}?")
        self.log(message, level)
      end
    end
    
    define_method "#{level}?" do
      LEVELS_MAP[level][1] >= LEVELS_MAP[@level][1]
    end
  end
  
  private 

    # Clean up messages so they're nice and pretty.
    # Taken from SyslogLogger
    def clean(message)
      message = message.to_s.dup
      message.strip!
      message.gsub!(/%/, '%%') # syslog(3) freaks on % (printf)
      message.gsub!(/\e\[[^m]*m/, '') # remove useless ansi color codes
      return message
    end

end
