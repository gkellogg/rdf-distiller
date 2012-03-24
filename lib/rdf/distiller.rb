require 'sinatra'

module RDF
  module Distiller
    autoload :VERSION,        'rdf/distiller/version'
    autoload :DISTILLER_HAML, 'rdf/distiller/rdfa_template'
    autoload :Application,    'rdf/distiller/application'
  end
end
