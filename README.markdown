# RDF::Distiller

Ruby-based RDF Distiller and SPARQL servce.

## DESCRIPTION
RDF::Distiller is Sinatra web portal for [RDF.rb][RDF.rb] library suite.

## FEATURES
Distills between formats supported in [Linked Data][linkeddata].

* Includes [N-Triples][] support using [RDF.rb][].
* Includes [N-Quads][] support using [RDF.rb][].
* Includes [Microdata][] support using the [RDF::Microdata][] gem.
* Includes [Notation3][] support using the [RDF::N3][] gem.
* Includes [RDFa][] support using the [RDF::RDFa][] gem.
* Includes [RDF/JSON][] support using the [RDF::JSON][] gem.
* Includes [RDF/XML][] support using the [RDF::RDFXML][] gem.
* Includes [TriG][] support using the [RDF::TriG][] gem.
* Includes [TriX][] support using the [RDF::TriX][] gem.
* Includes [Turtle][] support using the [RDF::Turtle][] gem.
* Includes [Microdata][] support using the [RDF::Microdata][] gem.
* Includes [JSON-LD][] support using the [JSON::LD][] gem.
* Includes [SPARQL][] support using the [SPARQL][SPARQL gem] gem.

## Dependencies
* [RDF.rb](http://rubygems.org/gems/rdf) (>= 0.3.5)
* [Linked Data](http://rubygems.org/gems/linkeddata) (>= 0.3.5)
* [Linked Data for Rack](http://rubygems.org/gems/rack-linkeddata) (>= 0.3.1)
* [Linked Data for Sinatra](http://rubygems.org/gems/sinatra-linkeddata) (>= 0.3.1)
* [Nokogiri](http://rubygems.org/gems/nokogiri) (>= 1.5.2)
* [RDF::JSON](http://rubygems.org/gems/rdf-json) (>= 0.3.0)
* [RDF::Microdata](http://rubygems.org/gems/rdf-microdata) (>= 0.2.3)
* [RDF::N3](http://rubygems.org/gems/rdf-n3) (>= 0.3.6)
* [RDF::RDFa](http://rubygems.org/gems/rdf-rdfa) (>= 0.3.10)
* [RDF::RDFXML](http://rubygems.org/gems/rdf-rdfxml) (>= 0.3.6)
* [RDF::TriG](http://rubygems.org/gems/rdf-trig) (>= 0.1.1)
* [RDF::TriX](http://rubygems.org/gems/rdf-trix) (>= 0.3.0)
* [RDF::Turtle](http://rubygems.org/gems/rdf-turtle) (>= 0.1.1)
* [JSON::LD](http://rubygems.org/gems/json-ld) (>= 0.1.1)
* [SPARQL](http://rubygems.org/gems/sparql) (>= 0.1.1)

## Documentation
### Core libraries
* {RDF RDF.rb}
  * {RDF::JSON}
  * {RDF::Microdata}
  * {RDF::N3}
  * {RDF::RDFa}
  * {RDF::RDFXML}
  * {RDF::TriG}
  * {RDF::TriX}
  * {RDF::Turtle}
  * {JSON::LD}

### Rollup libraries
* {LinkedData Linked Data}
  * {Rack::SPARQL Linked Data for Rack}
  * {Sinatra::SPARQL Linked Data for Sinatra}

### Query/Access
* {SPARQL}
* {SPARQL::Client SPARQL Client}
* {Spira}

### Storage
* {RDF::DO RDF Dataobjects}

## Resources
* [RDF Distiller](http://rdf.kellogg-assoc.com)

## AUTHOR
* [Gregg Kellogg](http://github.com/gkellogg) - <http://kellogg-assoc.com/>

## Hosting Notes
* public/.htaccess set up for installation on RailsPlayground server.
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

[RDF.rb]:         http://ruby-rdf.github.com/rdf
[RDF::JSON]:      http://rdf.rubyforge.org/json/
[RDF::Microdata]: http://rdoc.info/github/gkellogg/rdf-microdata/master/frames
[RDF::N3]:        http://rdoc.info/github/gkellogg/rdf-n3/master/frames
[RDF::RDFa]:      http://rdoc.info/github/gkellogg/rdf-rdfa/master/frames
[RDF::RDFXML]:    http://rdoc.info/github/gkellogg/rdf-rdfxml/master/frames
[RDF::TriG]:      http://rdoc.info/github/gkellogg/rdf-trig/master/frames
[RDF::TriX]:      http://rdf.rubyforge.org/trix/
[RDF::Turtle]:    http://rdoc.info/github/gkellogg/rdf-turtle/master/frames
[JSON::LD]:       http://rdoc.info/github/gkellogg/json-ld/master/frames
[SPARQL gem]:     http://rdoc.info/github/gkellogg/sparql/master/frames
[JSON-LD]:        http://json-ld.org/
[linkeddata]:     {file:readmes/linkeddata}
[Microdata]:      http://dev.w3.org/html5/md/
[N-Triples]:      http://en.wikipedia.org/wiki/N-Triples
[N-Quads]:        http://en.wikipedia.org/wiki/N-Quads
[Notation3]:      http://en.wikipedia.org/wiki/Notation3
[RDF/JSON]:       http://n2.talis.com/wiki/RDF_JSON_Specification
[RDF/XML]:        http://www.w3.org/TR/rdf-syntax-grammar/
[RDFa]:           http://en.wikipedia.org/wiki/RDFa
[SPARQL]:         http://en.wikipedia.org/wiki/Sparql
[TriG]:           http://en.wikipedia.org/wiki/TriG_(syntax)
[TriX]:           http://en.wikipedia.org/wiki/TriX_(syntax)
[Turtle]:         http://en.wikipedia.org/wiki/Turtle_(syntax)
