#!/usr/bin/env rackup
$:.unshift(File.expand_path('../lib',  __FILE__))

require 'rubygems' || Gem.clear_paths
require 'bundler'
Bundler.setup

require 'restclient/components'
require 'rack/cache'
require 'rdf/distiller'
require 'rdf/test'

set :environment, (ENV['RACK_ENV'] || 'production').to_sym

if ENV['RACK_ENV'] == 'production'
  use Rack::Cache,
    :verbose     => true,
    :metastore   => "file:" + File.expand_path("../cache/meta", __FILE__),
    :entitystore => "file:" + File.expand_path("../cache/body", __FILE__)
end

disable :run, :reload

class TurtleTest < RDF::Test::Application; end
TurtleTest.set :app_name, "Turtle Test Runner"
TurtleTest.set :test_uri, "http://www.w3.org/2013/TurtleTests/"
TurtleTest.set :short_name, "turtle"

run Rack::URLMap.new \
  "/"             => RDF::Distiller::Application,
  "/test/turtle"  => TurtleTest.new
