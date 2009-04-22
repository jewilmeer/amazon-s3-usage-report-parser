#!/usr/bin/ruby
# load application configuration
require File.join( File.dirname(__FILE__), 'config', 'boot')
# run the application
Logger.info "Starting application"
Application.new.run