source 'http://rubygems.org'

# Include non-released gems first
gem 'addressable',      '2.2.4'
gem 'rdf',              :git => "https://github.com/gkellogg/rdf.git", :branch => "type-check-mixin"
gem 'rdf-n3',           :git => "https://github.com/gkellogg/rdf-n3.git", :require => "rdf/n3"
gem 'rdf-rdfa',         :git => "https://github.com/gkellogg/rdf-rdfa.git", :require => "rdf/rdfa"
gem 'rdf-rdfxml',       :git => "https://github.com/gkellogg/rdf-rdfxml.git", :require => "rdf/rdfxml"
gem 'linkeddata',       :git => "https://github.com/gkellogg/linkeddata.git", :branch => "0.4.x", :require => "rdf/rdfxml"
gem 'rack-linkeddata',  :git => "https://github.com/gkellogg/rack-linkeddata.git", :branch => "0.4.x", :require => "rack/linkeddata"
gem 'rdf-isomorphic',   '>= 0.3.4', :require => 'rdf/isomorphic'
gem 'rdf-json',         :git => "https://github.com/gkellogg/rdf-json.git", :branch => "0.4.x", :require => 'rdf/json'
gem 'rdf-trix',         :git => "https://github.com/gkellogg/rdf-trix.git", :branch => "0.4.x", :require => 'rdf/trix'
gem 'rdf-do'
gem 'spira',            '>= 0.0.12'
gem 'sxp',              '>= 0.0.5'
gem 'sparql-client',    :git => "https://github.com/gkellogg/sparql-client.git", :branch => "0.4.x", :require => 'sparql/client'
gem 'sparql-algebra',   :git => "https://github.com/gkellogg/sparql-algebra.git", :require => 'sparql/algebra'
gem 'sparql-grammar',   :git => "https://github.com/gkellogg/sparql-grammar.git", :require => 'sparql/grammar'

gem 'sinatra',            '>= 1.2.1'
gem 'sinatra-linkeddata', :git => "https://github.com/gkellogg/sinatra-linkeddata.git", :branch => "0.4.x", :require => "sinatra/linkeddata"
gem 'erubis',             '>= 2.6.6'
gem 'haml',               '>= 3.0.0'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'shotgun'
end
