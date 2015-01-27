require 'logger'
require 'rdf'

module RDF
  module Test
    autoload :Application,          "rdf/test/application"
    autoload :Core,                 "rdf/test/core"
    autoload :VERSION,              "rdf/test/version"

    APP_DIR   = File.expand_path("../../..", __FILE__)
    CACHE_DIR = File.join(APP_DIR, 'cache')
    PUB_DIR   = File.join(APP_DIR, 'public')
  end
end