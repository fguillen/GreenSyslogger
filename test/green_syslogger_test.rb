require 'rubygems'
require 'test/unit'
require 'mocha'
require 'delorean'
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
    
    assert_equal('rails', @logger.instance_eval("@tag"))
    assert_equal('local2', @logger.instance_eval("@facility"))
    assert_equal(:debug, @logger.instance_eval("@level"))
    assert_equal(1, @logger.instance_eval("@max_buffer_size"))
  end
  
  def test_initialize_with_params
    Syslog.expects(:open).with('my tag', Syslog::LOG_PID, Syslog::LOG_LOCAL3).returns( @logger.instance_eval('@syslog') )
    @logger = GreenSyslogger.new('my tag', 'local3', :info)
    
    assert_equal('my tag', @logger.instance_eval("@tag"))
    assert_equal('local3', @logger.instance_eval("@facility"))
    assert_equal(:info, @logger.instance_eval("@level"))
    assert_equal(1, @logger.instance_eval("@max_buffer_size"))
  end
  
  def test_has_a_collection_of_methods
    GreenSyslogger::LEVELS_MAP.each_key do |level|
      @logger.expects(:add).with('rails', level, @message)
      @logger.send(level, @message)
    end
  end

  def test_debug_with_defaul_initialization
    @logger.expects(:auto_flush)
    
    Delorean.time_travel_to("2010-01-01 10:10:10") do
      @logger.debug('wadus message')
    end
    
    assert_equal([Time.parse('2010-01-01 10:10:10').to_s, 'rails', 'debug', 'wadus message'], @logger.instance_eval('buffer')[0].map { |e| e.to_s })
  end

  def test_log_in_debug_level
    @logger.level = :debug
    @logger.expects(:auto_flush).times(3)
    @logger.debug(@message)
    @logger.info(@message)
    @logger.error(@message)
  end

  def test_log_in_info_level
    @logger.level = :info
    @logger.expects(:auto_flush).times(2)
    @logger.debug(@message)
    @logger.info(@message)
    @logger.error(@message)
  end

  def test_log_with_custom_tag
    @logger.expects(:add).with('my tag', :info, @message)
    @logger.custom(@message, 'my tag')
  end
  
  def test_auto_flush_activate
    @logger.auto_flushing = true
    @logger.expects(:flush).times(1)
    @logger.debug('wadus message')
  end

  def test_auto_flush_deactivate
    old_max_buffer_size = GreenSyslogger::DEFAULT_MAX_BUFFER_SIZE
    GreenSyslogger.send(:remove_const, :DEFAULT_MAX_BUFFER_SIZE)
    GreenSyslogger.const_set(:DEFAULT_MAX_BUFFER_SIZE, 3)
    
    @logger.auto_flushing = false
    @logger.expects(:flush).times(1)
    
    @logger.debug('wadus message')
    @logger.debug('wadus message')
    @logger.debug('wadus message')
    
    GreenSyslogger.send(:remove_const, :DEFAULT_MAX_BUFFER_SIZE)
    GreenSyslogger.const_set(:DEFAULT_MAX_BUFFER_SIZE, old_max_buffer_size)
  end
  
  def test_flush
    @syslog = @logger.instance_eval('@syslog')
    Syslog.expects(:reopen).returns(@syslog).times(2)
    @syslog.expects(:debug).times(2)
    @syslog.expects(:info).times(2)
    
    @logger.auto_flushing = false
    @logger.debug('wadus debug')
    @logger.info('wadus info')
    @logger.custom('wadus custom tag info', 'new tag', :info)
    @logger.debug('wadus info again')

    @logger.flush
  end
  
  def test_especial_case_init_of_request
    @logger.expects(:auto_flush).twice
    @logger.info("\n\nStarted")
  end
end