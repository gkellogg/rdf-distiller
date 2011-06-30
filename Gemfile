source 'http://rubygems.org'

# Include non-released gems first
gem 'addressable',      '2.2.4'
gem 'rdf',              :git => "git://github.com/gkellogg/rdf.git", :branch => "type-check-mixin"
gem 'linkeddata',       :git => "git://github.com/gkellogg/linkeddata.git", :branch => "0.4.x", :require => "rdf/rdfxml"
gem 'rack-linkeddata',  :git => "git://github.com/gkellogg/rack-linkeddata.git", :branch => "0.4.x", :require => "rack/linkeddata"
gem 'rdf-json',         :git => "git://github.com/gkellogg/rdf-json.git", :branch => "0.4.x", :require => 'rdf/json'
gem 'rdf-trix',         :git => "git://github.com/gkellogg/rdf-trix.git", :branch => "0.4.x", :require => 'rdf/trix'
gem 'rdf-microdata',    '>= 0.1.0', :require => "rdf/microdata"
gem 'rdf-n3',           '>= 0.3.3', :require => "rdf/n3"
gem 'rdf-rdfa',         '>= 0.3.3', :require => "rdf/rdfa"
gem 'rdf-rdfxml',       '>= 0.3.3', :require => "rdf/rdfxml"
gem 'json-ld',          '>= 0.0.6', :require => 'json/ld'
gem 'rdf-isomorphic',   '>= 0.3.4', :require => 'rdf/isomorphic'
gem 'rdf-do'
gem 'spira',            '>= 0.0.12'
gem 'sxp',              '>= 0.0.5'
gem 'sparql-client',    :git => "git://github.com/gkellogg/sparql-client.git", :branch => "0.4.x", :require => 'sparql/client'
gem 'sparql-algebra',   :git => "git://github.com/gkellogg/sparql-algebra.git", :require => 'sparql/algebra'
gem 'sparql-grammar',   :git => "git://github.com/gkellogg/sparql-grammar.git", :require => 'sparql/grammar'

gem 'sinatra',            '>= 1.2.1'
gem 'sinatra-linkeddata', :git => "git://github.com/gkellogg/sinatra-linkeddata.git", :branch => "0.4.x", :require => "sinatra/linkeddata"
gem 'erubis',             '>= 2.6.6'
gem 'haml',               '>= 3.0.0'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'shotgun'
end
