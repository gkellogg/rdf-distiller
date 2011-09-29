# Default HAML templates used for generating output from the writer
module RDF::Portal
  DISTILLER_HAML = {
    :identifier => "distiller", 
    # Document
    # Locals: language, title, profile, prefix, base, subjects
    # Yield: subjects.each
    :doc => %q(
      !!! XML
      !!! 5
      %html{:xmlns => "http://www.w3.org/1999/xhtml", :lang => lang, :profile => profile, :prefix => prefix}
        - if base || title
          %head
            - if base
              %base{:href => base}
            - if title
              %title= title
            %link{:rel => "stylesheet", :href => "--root--/css/distiller.css", :type => "text/css"}
            %script{:src => "https://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js", :type => "text/javascript"}
            %script{:src => "--root--/js/distiller.js", :type => "text/javascript"}
        %body
          - if base
            %p= "RDFa serialization URI base: &lt;#{base}&gt;"
          - subjects.each do |subject|
            != yield(subject)
    ),

    # Output for non-leaf resources
    # Note that @about may be omitted for Nodes that are not referenced
    #
    # If _rel_ and _resource_ are not nil, the tag will be written relative
    # to a previous subject. If _element_ is :li, the tag will be written
    # with <li> instead of <div>.
    #
    # Note that @rel and @resource can be used together, or @about and @typeof, but
    # not both.
    #
    # Locals: subject, typeof, predicates, rel, element, inlist
    # Yield: predicates.each
    :subject => %q(
      - if element == :li
        %li{:rel => rel, :resource => resource, :inlist => inlist}
          - if typeof
            %span{:rel => 'rdf:type', :resource => typeof}.type!= typeof
          %table.properties
            - predicates.each do |predicate|
              != yield(predicate)
      - elsif rel && typeof
        %td{:rel => rel, :inlist => inlist}
          %div{:about => resource, :typeof => typeof}
            %span.type!= typeof
            %table.properties
              - predicates.each do |predicate|
                != yield(predicate)
      - elsif rel
        %td{:rel => rel, :resource => resource, :inlist => inlist}
          %table.properties
            - predicates.each do |predicate|
              != yield(predicate)
      - else
        %div{:about => about, :typeof => typeof}
          - if typeof
            %span.type!= typeof
          %table.properties
            - predicates.each do |predicate|
              != yield(predicate)
    ),

    # Output for single-valued properties
    # Locals: predicate, object, inlist
    # Yields: object
    # If nil is returned, render as a leaf
    # Otherwise, render result
    :property_value => %q(
      - if heading_predicates.include?(predicate) && object.literal?
        %h1{:property => get_curie(predicate), :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object), :inlist => inlist}= escape_entities(get_value(object))
      - else
        %tr.property
          %td.label
            = get_predicate_name(predicate)
          - if res = yield(object)
            != res
          - elsif get_curie(object) == 'rdf:nil'
            %td{:rel => get_curie(predicate), :inlist => ''}= "Empty"
          - elsif object.node?
            %td{:resource => get_curie(object), :rel => get_curie(predicate), :inlist => inlist}= get_curie(object)
          - elsif object.uri?
            %td
              %a{:href => object.to_s, :rel => get_curie(predicate), :inlist => inlist}= object.to_s
          - elsif object.datatype == RDF.XMLLiteral
            %td{:property => get_curie(predicate), :lang => get_lang(object), :datatype => get_dt_curie(object), :inlist => inlist}<!= get_value(object)
          - else
            %td{:property => get_curie(predicate), :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object), :inlist => inlist}= escape_entities(get_value(object))
    ),

    # Output for multi-valued properties
    # Locals: predicate, objects, inliste
    # Yields: object for leaf resource rendering
    :property_values =>  %q(
      %tr.property
        %td.label
          = get_predicate_name(predicate)
        %td
          %ul
            - objects.each do |object|
              - if res = yield(object)
                != res
              - elsif object.node?
                %li{:rel => get_curie(predicate), :resource => get_curie(object), :inlist => inlist}= get_curie(object)
              - elsif object.uri?
                %li
                  %a{:rel => get_curie(predicate), :href => object.to_s, :inlist => inlist}= object.to_s
              - elsif object.datatype == RDF.XMLLiteral
                %li{:property => get_curie(predicate), :lang => get_lang(object), :datatype => get_curie(object.datatype), :inlist => inlist}<!= get_value(object)
              - else
                %li{:property => get_curie(predicate), :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object), :inlist => inlist}= escape_entities(get_value(object))
    ),
  }
end