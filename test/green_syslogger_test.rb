require 'rubygems'
require 'test/unit'
require 'mocha'
require File.expand_path(File.dirname(__FILE__) + '/../lib/green_syslogger')


class GreenSysloggerTest < Test::Unit::TestCase
  
  def setup
    @logger = GreenSyslogger.new
    @message = "wadus message"
  end

  def teardown
    @logger.close
  end

  def test_initialize_by_default
    Syslog.expects(:open).with('rails', Syslog::LOG_PID, Syslog::LOG_LOCAL2).returns( @logger.instance_eval('@syslog') )
    @logger = GreenSyslogger.new
    assert_equal(:debug, @logger.instance_eval("@level"))
  end
  
  def test_initialize_with_params
    Syslog.expects(:open).with('my tag', Syslog::LOG_PID, Syslog::LOG_LOCAL3).returns( @logger.instance_eval('@syslog') )
    @logger = GreenSyslogger.new('my tag', 'local3', :info)
    assert_equal(:info, @logger.instance_eval("@level"))
  end
  
  def test_has_a_collection_of_methods
    GreenSyslogger::LEVELS_MAP.each_key do |level|
      @logger.expects(:log).with(@message, level)
      @logger.send(level, @message)
    end
  end

  def test_log
    @logger.instance_eval('@syslog').expects(:debug).with(@message)
    @logger.log(@message, :debug)
  end

  def test_log_cleaned
    @logger.expects(:clean).with(@message).returns("#{@message} cleaned")
    @logger.instance_eval('@syslog').expects(:debug).with("#{@message} cleaned")
    @logger.log(@message, :debug)
  end

  def test_clean
    dirty_message = "\x1B[[1m\x1B[[36mSQL (0.339ms)\x1B[[0m  \x1B[[1m select landing_page_id, count(*) cnt from transactions \n where landing_page_id in (4278,4279,4334,4338,4340,4342) \n and status >= 45 and created_at >= '2010-11-08T11:30:22'\n group by landing_page_id\n\x1B[[0m"
    clean_message = "SQL (0.339ms)   select landing_page_id, count(*) cnt from transactions \n where landing_page_id in (4278,4279,4334,4338,4340,4342) \n and status >= 45 and created_at >= '2010-11-08T11:30:22'\n group by landing_page_id\n"

    assert_equal(clean_message, @logger.send(:clean, dirty_message))
  end

  def test_log_in_debug_level
    @logger.level = :debug
    @logger.expects(:log).times(3)
    @logger.debug(@message)
    @logger.info(@message)
    @logger.error(@message)
  end

  def test_log_in_info_level
    @logger.level = :info
    @logger.expects(:log).times(2)
    @logger.debug(@message)
    @logger.info(@message)
    @logger.error(@message)
  end

  def test_log_with_custom_tag
    Syslog.expects(:reopen).returns(@logger.instance_eval('@syslog')).twice
    @logger.expects(:log)
    @logger.custom(@message)
  end

end