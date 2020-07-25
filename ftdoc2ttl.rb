
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'pp'

class INSDCCore
  def initialize
    @owl_core = File.read(File.dirname(__FILE__) + "/resources/core.ttl")
  end

  def read
    puts @owl_core
  end
end

class Features
  def initialize
    @data = JSON.parse(File.read(File.dirname(__FILE__) + "/resources/features.json"))
  end 

  def urls
    ff ={}
    @data['results']['bindings'].each{ |k| 
    # ff[k['feature']['value']]= k['label']['value']
       ff[k['label']['value']]= k['feature']['value']
    }
    return ff
  end
  # ftso = FT_SO.new
  # puts ftso.so_id("-10_signal")  # => "SO:0000175"
  def so_id(feature)
    if hash = @data[feature]
      return hash["so_id"]
    end 
  end 

  def so_term(feature)
    if hash = @data[feature]
      return hash["so_term"]
    end 
  end 

  def so_desc(feature)
    if hash = @data[feature]
      return hash["so_desc"]
    end 
  end 

  def ft_desc(feature)
    if hash = @data[feature]
      return hash["ft_desc"]
    end 
  end 
end


class FTdoc2OWL

  def initialize(params)
    @owl      = INSDCCore.new
    @features = Features.new
    #@locus = {}
    #@xref_warn = {}

    #pp params
    if params['full']
      @owl.read
    end
    #pp @features 
    @urls = @features.urls
    parse_ftdoc
    owl_add
    
  end 

  def parse_ftdoc
    fff ={}
    doc = Nokogiri::HTML(File.read(File.dirname(__FILE__) + "/resources/feature-table"))
    doc.css('pre').each do |pre|
      if /^The following has been organized according to the following format:/ =~ pre
        pre.content.gsub("\t","        ").gsub(/\n{1,}/m,"\n").split(/^Feature Key           /).slice(2..-1).each do |f|
          feature ={
            :feature_key => '',
            :definition  => '',
            :mandatory_qualifier => {},
            :optional_qualifier  => {},
            :example => '',
            :parent_key => '',
            :organism_scope => '',
            :molecule_scope => '',
            :references => '',
            :comment => ''
          }

          f ="Feature Key           #{f}"
          if /(Feature Key)\s+(\S+)?\n(Definition\s+.*)/m =~ f
              feature[:feature_key] = $2.strip
          end
          if /(Definition)\s+(.+?)\n(Mandatory qualifiers|Optional qualifiers)\s+.*/m =~ f
             feature[:definition] = $2.gsub(/(\n|\t|\s)+/," ")
          end
          if /(Mandatory qualifiers)\s+(.+?)\n(Optional qualifiers|Parent Key|Organism scope|Molecule scope|References|Comment)\s+.*/m =~ f
             #feature[:mandatory_qualifier] = $2.gsub(/\n\s+/,"\n").split("\n").map { |x| x.split('=')}
             feature[:mandatory_qualifier] = $2.sub(/ \(Note:.+\)?/m,"").gsub(/(?!\n\s+\/)\n\s+/,"").gsub(/\n\s+/,"\n").split("\n").map { |x| x.split('=')}
          end
          if /(Optional qualifiers)\s+(.+?)\n(Example\s+|Parent Key\s+|Molecule Scope\s+|Organism scope\s+|Molecule scope\s+|References\s+|Comment\s+|$)/m =~ f
             #feature[:optional_qualifier] = $2.gsub(/\n\s+/,"\n").split("\n").map { |x| x.split('=')}
             feature[:optional_qualifier] = $2.gsub(/(?!\n\s+\/)\n\s+/,"").gsub(/\n\s+/,"\n").split("\n").map { |x| x.split('=')}
          end
          if /(Parent Key)\s+(.+)?\n(Organism scope|Molecule scope|References|Comment)\s+.*/m =~ f
             feature[:parent_key] = $2.gsub(/(\n|\t|\s)+/," ")
          end
          if /(Organism scope)\s+(.+?)\n(Molecule scope\s+|References\s+|Comment|$)/m =~ f
             feature[:organism_scope] = $2.gsub(/(\n|\t|\s)+/," ")
          end
          if /(Molecule scope)\s+(.+?)\n(References\s+|Comment\s+|$)/m =~ f
             feature[:molecule_scope] = $2.gsub(/(\n|\t|\s)+/," ")
          end
          if /(References)\s+(.+)?\n(Comment\s+|$)/m =~ f
             feature[:references] = $2.gsub(/(\n|\t|\s)+/," ")
          end
          if /(Comment)\s+(.+)?\n/m =~ f
             feature[:comment] = $2.gsub(/(\n|\t|\s)+/," ")
          end

          fff[feature[:feature_key]] = feature
        end
      end
      if /^The following is a list of available qualifiers for feature keys and their usage./ =~ pre
         #pp pre.content.gsub("\n                      ","").split("Qualifier")
         #puts pre.content
      end
    end
    @fff =fff
  end

  def owl_add
    @fff.each { |k,v|
    #puts ff[k]
       v[:mandatory_qualifier].each do |mq,vv|
       mqr = mq.sub(/^\//,"").strip
       puts <<EOF
<#{@urls[k]}>
    owl:equivalentClass [
    owl:cardinality "1"^^xsd:nonNegativeInteger ;
    owl:onProperty <http://insdc.org/owl/#{mqr}>
    ] .

[]
    a owl:Axiom ;
    rdfs:isDefinedBy <http://insdc.org/owl/OptionalQualifier> ;
    owl:annotatedProperty owl:equivalentClass ;
    owl:annotatedSource <#{@urls[k]}> ;
    owl:annotatedTarget [
        a owl:Restriction ;
        owl:cardinality "1"^^xsd:nonNegativeInteger ;
        owl:onProperty <http://insdc.org/owl/#{mqr}>
    ] .  

EOF
      end

      v[:optional_qualifier].each do |mq,vv|
        oqr = mq.sub(/^\//,"").strip
        puts <<EOF
<#{@urls[k]}>
    rdfs:subClassOf [
    a owl:Restriction ;
    owl:maxCardinality "1"^^xsd:nonNegativeInteger ;
    owl:onProperty <http://insdc.org/owl/#{oqr}>
    ] .

[]
    a owl:Axiom ;
    rdfs:isDefinedBy <http://insdc.org/owl/OptionalQualifier> ;
    owl:annotatedProperty owl:equivalentClass ;
    owl:annotatedSource <#{@urls[k]}> ;
    owl:annotatedTarget [
        a owl:Restriction ;
        owl:maxCardinality "1"^^xsd:nonNegativeInteger ;
        owl:onProperty <http://insdc.org/owl/#{oqr}>
    ] .  

EOF
      end
    }
  end
end


if __FILE__ == $0
  require 'optparse'
  # ruby ftdoc2ttl.rb  --full
  # ToDo: 
  #  * Updating every year.
  #  * use SPARQL::Client
  params = ARGV.getopts("h:t:", "full", "feature:")
  #p params

  ttl_core      = 'resources/core.ttl' 
  features_json = 'resources/features.json' 
  html = 'resources/feature-table'

  FTdoc2OWL.new(params)
end

=begin


Optional qualifiers     optional qualifiers associated with the key
Organism scope          valid organisms for the key; if the scope is any
                        organism, this field is omitted.
Molecule scope          valid molecule types; if the scope is any molecule
                        type, this field is omitted.
References              citations of published reports, usually supporting the
                        feature consensus sequence
Comment                 comments and clarifications

-----------------

Feature Key           assembly_gap


Definition            gap between two components of a CON record that is 
                      part of a genome assembly;

Mandatory qualifiers  /estimated_length=unknown or &lt;integer&gt;
                      /gap_type="TYPE"
                      /linkage_evidence="TYPE" (Note: Mandatory only if the 
                      /gap_type is "within scaffold" or "repeat within
                      scaffold".If there are multiple types of linkage_evidence
                      they will appear as multiple /linkage_evidence="TYPE"
                      qualifiers. For all other types of assembly_gap
                      features, use of the /linkage_evidence qualifier is 
                      invalid.)

Comment               the location span of the assembly_gap feature for an 
                      unknown gap is 100 bp, with the 100 bp indicated as
                      100 "n"'s in sequence.
=end

