# RDF::Portal

Web portal for for [RDF.rb][RDF.rb].

## DESCRIPTION
RDF::Portal is Sinatra web portal for [RDF.rb][RDF.rb] library suite.

## FEATURES
Distills between formats supported in [Linked Data][linkeddata].

* Includes [N-Triples][] support using [RDF.rb][].
* Includes [RDF/XML][] support using the [RDF::RDFXML][] gem.
* Includes [Turtle][] and [Notation3][] support using the [RDF::N3][] gem.
* Includes [RDFa][] support using the [RDF::RDFa][] gem.
* Includes [RDF/JSON][] support using the [RDF::JSON][] gem.
* Includes [TriX][] support using the [RDF::TriX][] gem.

## Dependencies
* [RDF.rb][RDF.rb] (>= 0.3.0)
* [Linked Data](http://rubygems.org/gems/linkeddata) (>= 0.3.0)
* [Linked Data for Rack](http://rubygems.org/gems/rack-linkeddata) (>= 0.3.0)
* [Linked Data for Sinatra](http://rubygems.org/gems/sinatra-linkeddata) (>= 0.3.0)
* [Nokogiri](http://rubygems.org/gems/nokogiri) (>= 1.3.3)
* [RDF::JSON](http://rubygems.org/gems/rdf-json) (>= 0.3.0)
* [RDF::N3](http://rubygems.org/gems/rdf-n3) (>= 0.3.0)
* [RDF::RDFa](http://rubygems.org/gems/rdf-rdfa) (>= 0.3.0)
* [RDF::RDFXML](http://rubygems.org/gems/rdf-rdfxml) (>= 0.3.0)
* [RDF::TriX](http://rubygems.org/gems/rdf-trix) (>= 0.3.0)

### Principle Classes
* {RDF::Portal}

## Resources
* [RDF Portal](http://rdf.kellogg-assoc)

## AUTHOR
* [Gregg Kellogg](http://github.com/gkellogg) - <http://kellogg-assoc.com/>

## License

This is free and unencumbered public domain software. For more information,
see <http://unlicense.org/> or the accompanying {file:UNLICENSE} file.

## FEEDBACK

* gregg@kellogg-assoc.com
* <http://rubygems.org/rdf-portal>
* <http://github.com/gkellogg/rdf-portal>
* <http://lists.w3.org/Archives/Public/public-rdf-ruby/>

[linkeddata]:       http://linkeddata.org/
[N-Triples]:      http://en.wikipedia.org/wiki/N-Triples
[Notation3]:      http://en.wikipedia.org/wiki/Notation3
[RDF.rb]:           http://rdf.rubyforge.org/
[RDF/JSON]:       http://n2.talis.com/wiki/RDF_JSON_Specification
[RDF/XML]:        http://en.wikipedia.org/wiki/RDF/XML
[RDF::JSON]:        http://rdf.rubyforge.org/json/
[RDF::N3]:          http://rdoc.info/github/gkellogg/rdf-n3
[RDF::RDFa]:        http://rdoc.info/github/gkellogg/rdf-rdfa
[RDF::RDFXML]:      http://rdoc.info/github/gkellogg/rdf-rdfxml
[RDF::TriX]:        http://rdf.rubyforge.org/trix/
[RDFa]:           http://en.wikipedia.org/wiki/RDFa
[TriX]:           http://www.w3.org/2004/03/trix/
[Turtle]:         http://en.wikipedia.org/wiki/Turtle_(syntax)
