INSDC
=====

The INSDC and DDBJ databases standardisation effort


== sample querying sparql ==
* get all featues

select ?feature, ?label, ?comment from <http://insdc.org/> where 
{
?feature rdfs:subClassOf <http://insdc.org/owl/Feature>.
?feature rdfs:label ?label.
?feature rdfs:comment ?comment.
}


* get all qualifiers

select ?qualifier, ?qualifier_label, ?qualifier_comment where 
{
?qualifier rdfs:label ?qualifier_label.
?qualifier rdfs:comment ?qualifier_comment.
?qualifier rdfs:domain ?feature.
?feature rdfs:label ?feature_label.
} order by ?qualifier

* get qualifiers of source featuers

select ?feature_label, ?qualifier_label, ?qualifier_type,?qualifier_comment where {
?s owl:annotatedSource ?feature;
   owl:annotatedTarget [
        a owl:Restriction ;
        owl:onProperty ?qualifier
    ] .
?s <http://www.w3.org/2000/01/rdf-schema#isDefinedBy> ?o.
?qualifier rdfs:label ?qualifier_label.
?o rdfs:label ?qualifier_type.
?qualifier rdfs:comment ?qualifier_comment.
?qualifier rdfs:domain ?feature.
?feature rdfs:label ?feature_label.
#FILTER(?feature = <http://insdc.org/owl/Gene>
FILTER(?feature_label = "source")
} order by ?qualifier_type
