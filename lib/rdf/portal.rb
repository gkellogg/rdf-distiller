require 'sinatra'

module RDF
  module Portal
    autoload :VERSION,        'rdf/portal/version'
    autoload :DISTILLER_HAML, 'rdf/portal/rdfa_template'
    autoload :Application,    'rdf/portal/application'
  end
end
