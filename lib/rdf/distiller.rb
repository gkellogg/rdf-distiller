require 'sinatra'
autoload :EBNF, "ebnf"
autoload :SXP, "sxp"

module RDF
  autoload :AggregateRepo, "rdf/aggregate_repo"
  autoload :XSD,           "rdf/xsd"

  module Distiller
    autoload :VERSION,        'rdf/distiller/version'
    autoload :DISTILLER_HAML, 'rdf/distiller/rdfa_template'
    autoload :Application,    'rdf/distiller/application'
  end
end
