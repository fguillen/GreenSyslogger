# GreenLogger

![GreenSyslogger logo](http://farm5.static.flickr.com/4060/5161504974_7dae687d7b_o_d.jpg)

Syslogger that makes your life greener

## Install

    $ [sudo] gem install green_syslogger

## Usage

    require 'green_syslogger'
    logger = GreenSyslogger.new
    logger.debug( 'debug message' )
   
To configure it on the <RAILS_ENVIRONMENT>.rb:

    config.logger = GreenSyslogger.new(<default tag>, <facility>, <level>)


By default

    GreenSyslogger.new('rails', 'local2', :debug)


To use it: 

    logger.debug("my debug message")
    logger.error("my error message")


To user another tag:

    logger.custom("my custom message", <tag>, <level>)


By default:

    logger.custom("my custom message", 'custom', :info)

## TODO


## Credits

* Authors: [Fernando Guillen](http://fernandoguillen.info) & [Juan Jose Vidal](http://twitter.com/j2vidal)
* Copyright: SponsorPay GmbH (c) 2010
* License: Released under the MIT license.

