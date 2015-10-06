require 'spec_helper'
require 'converter_spec_helper'

require_relative '../model/unlv_marcxml_converter'

describe 'MARCXML Accession converter' do

  def my_converter
    UNLVMarcXMLAgentsConverter
    # MarcXMLAccessionConverter
  end

  describe "Single Agent MARCXML to Accession" do
    def test_doc_1
      src = <<END
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <collection xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd" xmlns="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <record>
              <leader>00000npc a2200000 u 4500</leader>
              <controlfield tag="008">130109i19601970xx                  eng d</controlfield>
              <datafield tag="040" ind2=" " ind1=" ">
                  <subfield code="a">Repositories.Agency Code-AT</subfield>
                  <subfield code="b">eng</subfield>
                  <subfield code="c">Repositories.Agency Code-AT</subfield>
                  <subfield code="e">dacs</subfield>
              </datafield>
              <datafield tag="041" ind2=" " ind1="0">
                  <subfield code="a">eng</subfield>
              </datafield>
              <datafield tag="099" ind2=" " ind1=" ">
                  <subfield code="a">Resource.ID.AT</subfield>
              </datafield>
              <datafield tag="245" ind2=" " ind1="1">
                  <subfield code="a">SF A</subfield>
                  <subfield code="c">SF C</subfield>
                  <subfield code="h">SF H</subfield>
                  <subfield code="n">SF N</subfield>
              </datafield>
              <datafield tag="300" ind2=" " ind1=" ">
                  <subfield code="a">5.0 Linear feet</subfield>
                  <subfield code="f">Resource-ContainerSummary-AT</subfield>
              </datafield>
              <datafield tag="342" ind2="5" ind1="1">
                  <subfield code="i">SF I</subfield>
                  <subfield code="p">SF P</subfield>
                  <subfield code="q">SF Q</subfield>
              </datafield>
              <datafield tag="506" ind2=" " ind1="2">
                  <subfield code="3">SF 3</subfield>
                  <subfield code="c">SF C</subfield>
                  <subfield code="x">SF X</subfield>
              </datafield>
              <datafield tag="510" ind2=" " ind1="2">
                  <subfield code="3">SF 3</subfield>
                  <subfield code="c">SF C</subfield>
                  <subfield code="x">SF X</subfield>
              </datafield>
              <datafield tag="520" ind2=" " ind1="2">
                  <subfield code="a">SF A</subfield>
                  <subfield code="b">SF B</subfield>
                  <subfield code="c">SF C</subfield>
              </datafield>
              <datafield tag="540" ind2=" " ind1="2">
                  <subfield code="a">SF A</subfield>
              </datafield>
              <datafield tag="541" ind2=" " ind1="2">
                  <subfield code="a">541 SF A</subfield>
              </datafield>
              <datafield tag="561" ind2=" " ind1="2">
                  <subfield code="a">561 SF A</subfield>
              </datafield>
              <datafield tag="630" ind2=" " ind1="2">
                  <subfield code="d">SF D</subfield>
                  <subfield code="f">SF F</subfield>
                  <subfield code="x">SF X</subfield>
                  <subfield code="2">SF 2</subfield>
              </datafield>
              <datafield tag="691" ind2=" " ind1="2">
                  <subfield code="d">SF D</subfield>
                  <subfield code="a">SF A</subfield>
                  <subfield code="x">SF X</subfield>
                  <subfield code="3">SF 3</subfield>
              </datafield>
              <datafield tag="700" ind2=" " ind1="1">
                <subfield code="a">NAME 1</subfield>
                <subfield code="b">PName-Number-AT</subfield>
            		<subfield code="c">PNames-Prefix-AT, PNames-Title-AT, PNames-Suffix-AT</subfield>
            		<subfield code="d">PNames-Dates-AT</subfield>
            		<subfield code="q">PNames-FullerForm-AT</subfield>
            		<subfield code="g">PNames-Qualifier-AT</subfield>
            		<subfield code="e">Creator (cre)</subfield>
        			</datafield>

              <datafield tag="700" ind2=" " ind1="1">
                <subfield code="a">NAME 2</subfield>
                <subfield code="b">PName-Number-AT</subfield>
            		<subfield code="c">PNames-Prefix-AT, PNames-Title-AT, PNames-Suffix-AT</subfield>
            		<subfield code="d">PNames-Dates-AT</subfield>
            		<subfield code="q">PNames-FullerForm-AT</subfield>
            		<subfield code="g">PNames-Qualifier-AT</subfield>
            		<subfield code="e">Creator (cre)</subfield>
        			</datafield>
          </record>
     </collection>
END

      get_tempfile_path(src)
    end


    before(:all) do
      parsed = convert(test_doc_1)
      @accession = parsed.last
      @people = parsed.select{|r| r['jsonmodel_type'] == 'agent_person'}
      p @people.inspect
    end

    it "only creates a single agent with a single name if given two 700 fields" do
      @people.count.should eq(1)
      @accession['linked_agents'].count.should eq(1)

      @people.first['names'].count.should eq(1)
      @people.first['names'].first['primary_name'].should eq('NAME 1 NAME 2')
    end

  end
end

