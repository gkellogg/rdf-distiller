#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

GEMSPEC = Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'rdf-portal'
  gem.homepage           = 'http://gkellogg/rdf-portal/'
  gem.license            = 'Public Domain' if gem.respond_to?(:license=)
  gem.summary            = 'Web portal for RDF.rb.'
  gem.description        = gem.summary

  gem.authors            = ['Gregg Kellogg']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS README.md UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  gem.bindir             = %q(bin)
  gem.executables        = %w()
  gem.default_executable = gem.executables.first
  gem.require_paths      = %w(lib)
  gem.extensions         = %w()
  gem.test_files         = %w()
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 1.8.7'
  gem.requirements               = []
  gem.add_runtime_dependency     'sinatra',             '>= 1.2.1'
  gem.add_runtime_dependency     'sinatra-linkeddata',  '>= 0.3.0'
  gem.add_runtime_dependency     'erubis',              '>= 2.6.6'
  gem.add_development_dependency 'yard' ,               '>= 0.6.0'
  gem.add_development_dependency 'rspec',               '>= 2.5.0'
  gem.add_development_dependency 'shotgun',             '>= 0.9'
  gem.post_install_message       = nil
end
