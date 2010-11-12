require 'syslog'

#
# Custom Rails Logger
#
# * Use Syslog like back storage
# * Posibility to use custom 'facility'
# * Posibility to use custom 'tag'
# * Posibility to use custom 'tag' only in a concrete point so you can configure Syslog to filter this concrete message to another file
# * Compatible with `config.logger.auto_flushing = false` so every log of a simple request will be written on an atomic way
#
#     require 'green_syslogger'
#     logger = GreenSyslogger.new
#     logger.debug( 'debug message' )
# 
# To configure it on the <RAILS_ENVIRONMENT>.rb:
# 
#     config.logger = GreenSyslogger.new([<default tag>], [<facility>], [<level>])
# 
# By default
# 
#     GreenSyslogger.new('rails', 'local2', :debug)
# 
# Example for Rails configuration:
# 
#     config.log_level = :info
#     config.logger = GreenSyslogger.new('myapp', 'local1', config.log_level)
#     config.colorize_logging = false
#     config.logger.auto_flushing = false
# 
# To use it: 
# 
#     logger.debug("my debug message")
#     logger.error("my error message")
# 
# To use another tag:
# 
#     logger.custom("my custom message", [<tag>], [<level>])
# 
# By default:
# 
#     logger.custom("my custom message", 'custom', :info)
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
    :unknown  => [:debug    , 5]
  }
  
  DEFAULT_MAX_BUFFER_SIZE = 500
  
  def initialize(tag = 'rails', facility = 'local2', level = :debug)
    @tag = tag
    @facility = facility
    @level = level
    @max_buffer_size = 1
    @buffer = {}
    @guard = Mutex.new
    @syslog = Syslog.open(@tag, Syslog::LOG_PID, Syslog.const_get("LOG_#{@facility.upcase}"))
  end
  
  def close
    @syslog.close
  end

  # This method is a kind of a back door, using it you can 
  # change the 'tag' with this message is tagged.
  #
  # level default to 'info'
  # tag default 'ids-custom'
  def custom(message, tag = 'custom', level = :info)
    add(tag, level, message)
  end
  
  LEVELS_MAP.each_key do |level|
    define_method level do |message|
      add(@tag, level, message)
    end
    
    define_method "#{level}?" do
      level?(level)
    end
  end
  
  
  # If it is set to 'true' every line will be sent in the time is wrotten
  # If it is set to 'false' the buffer will be flushed at the end of the request by Rails
  # There is a DEFAULT_MAX_BUFFER_SIZE security buffer size
  #
  # only true or false
  def auto_flushing=(value)
    @max_buffer_size = value ? 1 : DEFAULT_MAX_BUFFER_SIZE
  end
  
  def flush
    @guard.synchronize do
      buffer.each do |buff|
        date = buff[0]
        tag = buff[1]
        level = buff[2]
        message = buff[3]
        
        message = "[#{date.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
        
        if(tag == @tag)
          @syslog.send(LEVELS_MAP[level][0], message)
        else
          @syslog = Syslog.reopen(tag, Syslog::LOG_PID, Syslog.const_get("LOG_#{@facility.upcase}"))
          @syslog.send(LEVELS_MAP[level][0], message)
          @syslog = Syslog.reopen(@tag, Syslog::LOG_PID, Syslog.const_get("LOG_#{@facility.upcase}"))
        end
      end
    end
    
    clear_buffer
  end
  
  
  private
  
    def level?(level)
      LEVELS_MAP[level][1] >= LEVELS_MAP[@level][1]
    end
    
    def add(tag, level, message)
      if(level?(level))
        # The init of the request
        if( message.gsub!("\n\nStarted", 'Started') )
          add(tag, level, '---')
        end
        
        buffer << [Time.now, tag, level, message]
        auto_flush
      end
    end
    
    def auto_flush
      self.flush  if buffer.size >= @max_buffer_size
    end

    def buffer
      @buffer[Thread.current] ||= []
    end

    def clear_buffer
      @buffer.delete(Thread.current)
    end
    
    # This is really only for debbugging
    def log_to_file(message)
      File.open("/tmp/my.log", 'w') do |f| 
        f.write(">> #{message}\n")
        f.flush
      end
    end
    
end
