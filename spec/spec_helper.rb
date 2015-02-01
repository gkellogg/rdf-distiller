$:.unshift File.expand_path("../../lib", __FILE__)
require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'rspec/its'
require 'rack/test'
require 'webmock/rspec'
require 'rdf/distiller'
require 'rdf/test'
require 'restclient/components'
require 'rack/cache'
require 'matchers'
require 'logger'

set :environment, :test

::RSpec.configure do |c|
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
  c.include ::Rack::Test::Methods

  def mime_type(sym)
    ::Sinatra::Base.mime_type(sym)
  end

  WebMock.allow_net_connect!
end
