require 'rubygems'
require 'bundler'

Bundler.setup :default, :development, :test

RSpec.configure do |c|
  c.mock_with :rspec
  c.formatter = "progress"
  c.tty = true if defined?(JRUBY_VERSION)
  c.color_enabled = true
end

$:.push File.expand_path('..', File.dirname(__FILE__))
$:.push File.expand_path('../lib', File.dirname(__FILE__))

require "turntable_api"
