$:.unshift File.expand_path("../../lib", __FILE__)
require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'rack/test'
require 'rdf/portal'
require 'matchers'

set :environment, :test

::RSpec.configure do |c|
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
  c.exclusion_filter = {
    :ruby => lambda { |version| !(RUBY_VERSION.to_s =~ /^#{version.to_s}/) },
  }
  c.include ::Rack::Test::Methods

  def app
   ::RDF::Portal::Application
  end

  def mime_type(sym)
    ::Sinatra::Base.mime_type(sym)
  end
end
