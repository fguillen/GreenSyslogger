# GreenLogger

![GreenSyslogger logo](http://farm5.static.flickr.com/4060/5161504974_7dae687d7b_o_d.jpg)

Syslogger that makes your life greener

Custom Rails Logger

* Use Syslog like back storage
* Posibility to use custom 'facility'
* Posibility to use custom 'tag'
* Posibility to use custom 'tag' only in a concrete point so you can configure Syslog to filter this concrete message to another file
* Compatible with `config.logger.auto_flushing = false` so every log of a simple request will be written on an atomic way

## Install

    $ [sudo] gem install green_syslogger

## Usage

    require 'green_syslogger'
    logger = GreenSyslogger.new
    logger.debug( 'debug message' )

To configure it on the <RAILS_ENVIRONMENT>.rb:

    config.logger = GreenSyslogger.new([<default tag>], [<facility>], [<level>])

By default

    GreenSyslogger.new('rails', 'local2', :debug)

Example for Rails configuration:

    config.log_level = :info
    config.logger = GreenSyslogger.new('myapp', 'local1', config.log_level)
    config.colorize_logging = false
    config.logger.auto_flushing = false

To use it: 

    logger.debug("my debug message")
    logger.error("my error message")

To use another tag:

    logger.custom("my custom message", [<tag>], [<level>])

By default:

    logger.custom("my custom message", 'custom', :info)

## TODO

In the `GreenSyslogger.custom` there are two reopen connections just to be allowed to change the `tag`, could be better to change the `tag` without reconnect.

There is not `GreenSyslogger.silencer`. Maybe is a good idea to implemented.

## Change log

### v 0.2.0

* Compatible with `config.logger.auto_flushing = false` so every log of a simple request will be written on an atomic way


## Credits

* Authors: [Fernando Guillen](http://fernandoguillen.info) & [Juan Jose Vidal](http://twitter.com/j2vidal)
* Copyright: SponsorPay GmbH (c) 2010
* License: Released under the MIT license.

