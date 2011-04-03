source 'http://rubygems.org'

# Include non-released gems first
gem 'rdf',                :git => "https://github.com/gkellogg/rdf.git", :branch => "query-algebra"
gem 'rdf-n3',             :git => "https://github.com/gkellogg/rdf-n3.git", :require => "rdf/n3"
gem 'rdf-rdfa',           :git => "https://github.com/gkellogg/rdf-rdfa.git", :require => "rdf/rdfa"
gem 'rdf-rdfxml',         :git => "https://github.com/gkellogg/rdf-rdfxml.git", :require => "rdf/rdfxml"

gem 'sinatra',            '>= 1.2.1'
gem 'sinatra-linkeddata', '>= 0.3.0', :require => 'sinatra/linkeddata'
gem 'erubis',             '>= 2.6.6'
gem 'haml',               '>= 3.0.0'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'shotgun'
end
