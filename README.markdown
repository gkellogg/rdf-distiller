# RDF::Portal

Web portal for for [RDF.rb][RDF.rb].

## DESCRIPTION
RDF::Portal is Sinatra web portal for [RDF.rb][RDF.rb] library suite.

## FEATURES
Distills between formats supported in [Linked Data][linkeddata].

* Includes [N-Triples][] support using [RDF.rb][].
* Includes [Notation3][] support using the [RDF::N3][] gem.
* Includes [RDFa][] support using the [RDF::RDFa][] gem.
* Includes [RDF/JSON][] support using the [RDF::JSON][] gem.
* Includes [RDF/XML][] support using the [RDF::RDFXML][] gem.
* Includes [TriX][] support using the [RDF::TriX][] gem.
* Includes [Turtle][] support using the [RDF::Turtle][] gem.
* Includes [Microdata][] support using the [RDF::Microdata][] gem.
* Includes [JSON-LD][] support using the [JSON::LD][] gem.

## Dependencies
* [RDF.rb](http://rubygems.org/gems/rdf) (>= 0.3.3)
* [Linked Data](http://rubygems.org/gems/linkeddata) (>= 0.3.2)
* [Linked Data for Rack](http://rubygems.org/gems/rack-linkeddata) (>= 0.3.1)
* [Linked Data for Sinatra](http://rubygems.org/gems/sinatra-linkeddata) (>= 0.3.1)
* [Nokogiri](http://rubygems.org/gems/nokogiri) (>= 1.4.4)
* [RDF::JSON](http://rubygems.org/gems/rdf-json) (>= 0.3.1)
* [RDF::Microdata](http://rubygems.org/gems/rdf-microdata) (>= 0.1.0)
* [RDF::N3](http://rubygems.org/gems/rdf-n3) (>= 0.3.5)
* [RDF::RDFa](http://rubygems.org/gems/rdf-rdfa) (>= 0.3.6)
* [RDF::RDFXML](http://rubygems.org/gems/rdf-rdfxml) (>= 0.3.4)
* [RDF::TriX](http://rubygems.org/gems/rdf-trix) (>= 0.3.1)
* [RDF::Turtle](http://rubygems.org/gems/rdf-turtle) (>= 0.0.5)
* [JSON::LD](http://rubygems.org/gems/json-ld) (>= 0.0.7)

## Documentation
### Core libraries
* {file:rdf-README RDF.rb}
  * {file:rdf-json-README RDF::JSON}
  * {file:rdf-microdata-README RDF::Microdata}
  * {file:rdf-n3-README RDF::N3}
  * {file:rdf-rdfa-README RDF::RDFa}
  * {file:rdf-rdfxml-README RDF::RDFXML}
  * {file:rdf-trix-README RDF::TriX}
  * {file:json-ld-README JSON::LD}

### Rollup libraries
* {file:linkeddata-README Linked Data}
  * {file:rack-linkeddata-README Linked Data for Rack}
  * {file:sinatra-linkeddata-README Linked Data for Sinatrra}

### Query/Access
* {file:sparql-algebra-README SPARQL Algebra}
* {file:sparql-client-README SPARQL Client}
* {file:sparql-grammar-README SPARQL Grammar}
* {file:spira-README Spira}

### Storage
* {file:rdf-do-README RDF Dataobjects}

## Resources
* [RDF Portal](http://rdf.kellogg-assoc.com)

## AUTHOR
* [Gregg Kellogg](http://github.com/gkellogg) - <http://kellogg-assoc.com/>

## Site5 Notes
* public/.htaccess set up for installation on Site5 server.
* Bundle installed using:

    bundle install --path vendor/bundler

## License

This is free and unencumbered public domain software. For more information,
see <http://unlicense.org/> or the accompanying {file:UNLICENSE} file.

## FEEDBACK

* gregg@kellogg-assoc.com
* <http://rubygems.org/rdf-portal>
* <http://github.com/gkellogg/rdf-portal>
* <http://lists.w3.org/Archives/Public/public-rdf-ruby/>

[JSON-LD]:        http://json-ld.org/spec/latest/
[linkeddata]:     {file:linkeddata-README}
[Microdata]:      http://dev.w3.org/html5/md/
[N-Triples]:      http://en.wikipedia.org/wiki/N-Triples
[Notation3]:      http://en.wikipedia.org/wiki/Notation3
[RDF/JSON]:       http://n2.talis.com/wiki/RDF_JSON_Specification
[RDF/XML]:        http://www.w3.org/TR/rdf-syntax-grammar/
[RDFa]:           http://en.wikipedia.org/wiki/RDFa
[TriX]:           http://en.wikipedia.org/wiki/TriX_(syntax)
[Turtle]:         http://en.wikipedia.org/wiki/Turtle_(syntax)
