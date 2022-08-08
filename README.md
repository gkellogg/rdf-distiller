# RDF::Distiller

Ruby-based RDF Distiller and SPARQL service.

[![Build Status](https://github.com/gkellogg/rdf-distiller/workflows/CI/badge.svg?branch=develop)](https://github.com/gkellogg/rdf-distiller/actions?query=workflow%3ACI)

## DESCRIPTION
RDF::Distiller is Sinatra web portal for [RDF.rb][RDF.rb] library suite.

## FEATURES
Distills between formats supported in [Linked Data][].

* Includes [N-Triples][] support using [RDF.rb][].
* Includes [N-Quads][] support using [RDF.rb][].
* Includes [Microdata][] support using the [RDF::Microdata][] gem.
* Includes [Notation3][] support using the [RDF::N3][] gem.
* Includes [RDFa][] support using the [RDF::RDFa][] gem.
* Includes [RDF/JSON][] support using the [RDF::JSON][] gem.
* Includes [RDF/XML][] support using the [RDF::RDFXML][] gem.
* Includes [CSV][] and [TSV][] support using the [RDF::Tabular][] gem.
* Includes [TriG][] support using the [RDF::TriG][] gem.
* Includes [TriX][] support using the [RDF::TriX][] gem.
* Includes [Turtle][] support using the [RDF::Turtle][] gem.
* Includes [Microdata][] support using the [RDF::Microdata][] gem.
* Includes [JSON-LD][] support using the [JSON::LD][] gem.
* Includes [YAML-LD][] support using the [YAML_LD][]  gem.
* Includes [SHACL][] support using the [SHACL][SHACL gem] gem.
* Includes [ShEx][] support using the [ShEx][ShEx gem] gem.
* Includes [SPARQL][] support using the [SPARQL][SPARQL gem] gem.
* Includes additional vocabularies using the [RDF::Vocab][] gem.

## Documentation
### Core libraries
* {RDF RDF.rb}
  * {RDF::JSON}
  * {RDF::Microdata}
  * {RDF::N3}
  * {RDF::RDFa}
  * {RDF::RDFXML}
  * {RDF::Reasoner}
  * {RDF::Tabular}
  * {RDF::TriG}
  * {RDF::TriX}
  * {RDF::Turtle}
  * {RDF::Vocab}
  * {RDF::XSD}
  * {JSON::LD}

### Rollup libraries
* [Linked Data][LinkedData]
  * {Rack::SPARQL Linked Data for Rack}
  * {Sinatra::SPARQL Linked Data for Sinatra}

### Query/Access
* {SHACL}
* {ShEx}
* {SPARQL}
* {SPARQL::Client SPARQL Client}
* {Spira}

### Storage
* {RDF::DO RDF Dataobjects}

## Resources
* [RDF Distiller](https://rdf.greggkellogg.net)

## Author
* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

## Hosting Notes
* Setup to run on Heroku.
* To run locally, do the following: `foreman start`

## Contributing
This repository uses [Git Flow](https://github.com/nvie/gitflow) to mange development and release activity. All submissions _must_ be on a feature branch based on the _develop_ branch to ease staging and integration.

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `.gemspec`, `VERSION` or `AUTHORS` files. If you need to
  change them, do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the corresponding
  list in the the `README`. Alphabetical order applies.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you,
  which you will be asked to agree to on the first commit to a repo within the organization.

## License

This is free and unencumbered public domain software. For more information,
see <https://unlicense.org/> or the accompanying {file:UNLICENSE} file.

## Resources

* gregg@greggkellogg.net
* <https://github.com/gkellogg/rdf-distiller>
* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

[RDF.rb]:         https://ruby-rdf.github.io/rdf
[RDF::JSON]:      https://ruby-rdf.github.io/rdf-json/
[RDF::Microdata]: https://ruby-rdf.github.io/rdf-microdata
[RDF::N3]:        https://ruby-rdf.github.io/rdf-n3
[RDF::RDFa]:      https://ruby-rdf.github.io/rdf-rdfa
[RDF::RDFXML]:    https://ruby-rdf.github.io/rdf-rdfxml
[RDF::Tabular]:   https://ruby-rdf.github.io/rdf-tabular
[RDF::TriG]:      https://ruby-rdf.github.io/rdf-trig
[RDF::TriX]:      https://ruby-rdf.github.io/rdf-trix/
[RDF::Turtle]:    https://ruby-rdf.github.io/rdf-turtle
[RDF::Vocab]:     https://ruby-rdf.github.io/rdf-vocab
[JSON::LD]:       https://ruby-rdf.github.io/json-ld
[SHACL gem]:      https://ruby-rdf.github.io/shacl
[ShEx gem]:       https://ruby-rdf.github.io/shex
[SPARQL gem]:     https://ruby-rdf.github.io/sparql
[JSON-LD]:        https://json-ld.org/
[YAML_LD]:           https://ruby-rdf.github.io/yaml-ld
[Microdata]:      https://dev.w3.org/html5/md/
[N-Triples]:      https://en.wikipedia.org/wiki/N-Triples
[N-Quads]:        https://en.wikipedia.org/wiki/N-Quads
[Notation3]:      https://en.wikipedia.org/wiki/Notation3
[LinkedData]:     https://ruby-rdf.github.io/linkeddata
[Linked Data]:    https://en.wikipedia.org/wiki/LinkedData
[RDF/JSON]:       https://n2.talis.com/wiki/RDF_JSON_Specification
[RDF/XML]:        https://www.w3.org/TR/rdf-syntax-grammar/
[RDFa]:           https://en.wikipedia.org/wiki/RDFa
[SHACL]:          https://en.wikipedia.org/wiki/SHACL
[ShEx]:           https://en.wikipedia.org/wiki/ShEx
[SPARQL]:         https://en.wikipedia.org/wiki/Sparql
[TriG]:           https://en.wikipedia.org/wiki/TriG_(syntax)
[TriX]:           https://en.wikipedia.org/wiki/TriX_(syntax)
[Turtle]:         https://en.wikipedia.org/wiki/Turtle_(syntax)
[CSV]:            https://en.wikipedia.org/wiki/Comma-separated_values
[TSV]:            https://en.wikipedia.org/wiki/Tab-separated_values
[YAML-LD]: https://json-ld.github.io/yaml-ld/spec
[YARD]:           https://yardoc.org/
[YARD-GS]:        https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:            https://unlicense.org/#unlicensing-contributions
