#!/usr/bin/env rackup
$:.unshift(File.expand_path('../lib',  __FILE__))

require 'rubygems' || Gem.clear_paths
require 'bundler'
Bundler.setup

require 'restclient/components'
require 'rack/cache'
require 'rdf/distiller'

set :environment, (ENV['RACK_ENV'] || 'develop').to_sym

if ENV['RACK_ENV'] == 'production'
  use Rack::Cache,
    verbose:    true,
    metastore:   "file:" + File.expand_path("../cache/meta", __FILE__),
    entitystore: "file:" + File.expand_path("../cache/body", __FILE__)
end

disable :run, :reload

run Rack::URLMap.new \
  "/"       => RDF::Distiller::Application
