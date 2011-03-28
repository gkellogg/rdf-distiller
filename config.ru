#!/usr/bin/env rackup
$:.unshift(File.expand_path('../lib',  __FILE__))

#log = File.new('sinatra.log', 'a')
#STDOUT.reopen(log)
#STDERR.reopen(log)

require 'rubygems' || Gem.clear_paths
require 'bundler'
Bundler.setup

require 'rdf/portal'

set :environment, :production
disable :run, :reload

run RDF::Portal::Application