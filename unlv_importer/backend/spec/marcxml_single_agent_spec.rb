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
      <marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
		<marc:record>
			<marc:leader>00612cz a2200181n 4500</marc:leader>
			<marc:controlfield tag="001">n 2003051366</marc:controlfield>
			<marc:controlfield tag="003">DLC</marc:controlfield>
			<marc:controlfield tag="005">20130522073928.0</marc:controlfield>
			<marc:controlfield tag="008">030806n| azannaabn |n aaa</marc:controlfield>
			<marc:datafield tag="010" ind1=" " ind2=" ">
				<marc:subfield code="a">n 2003051366</marc:subfield>
			</marc:datafield>
			<marc:datafield tag="035" ind1=" " ind2=" ">
				<marc:subfield code="a">(OCoLC)oca06121717</marc:subfield>
			</marc:datafield>
			<marc:datafield tag="040" ind1=" " ind2=" ">
				<marc:subfield code="a">DLC</marc:subfield>
				<marc:subfield code="b">eng</marc:subfield>
				<marc:subfield code="e">rda</marc:subfield>
				<marc:subfield code="c">DLC</marc:subfield>
				<marc:subfield code="d">IlMpPL</marc:subfield>
			</marc:datafield>
			<marc:datafield tag="046" ind1=" " ind2=" ">
				<marc:subfield code="f">19390726</marc:subfield>
			</marc:datafield>
			<marc:datafield tag="100" ind1="1" ind2=" ">
				<marc:subfield code="a">Goodman, Oscar Baylin,</marc:subfield>
				<marc:subfield code="d">1939-</marc:subfield>
			</marc:datafield>
			<marc:datafield tag="370" ind1=" " ind2=" ">
				<marc:subfield code="a">Philadelphia, Pa.</marc:subfield>
				<marc:subfield code="f">Las Vegas, Nev.</marc:subfield>
			</marc:datafield>
			<marc:datafield tag="374" ind1=" " ind2=" ">
				<marc:subfield code="a">Lawyers</marc:subfield>
				<marc:subfield code="a">Mayors</marc:subfield>
				<marc:subfield code="2">lcsh.</marc:subfield>
			</marc:datafield>
			<marc:datafield tag="375" ind1=" " ind2=" ">
				<marc:subfield code="a">male.</marc:subfield>
			</marc:datafield>
			<marc:datafield tag="670" ind1=" " ind2=" ">
				<marc:subfield code="a">Smith, J.L. Of rats and men, c2003:</marc:subfield>
				<marc:subfield code="b">
				t.p. (Oscar Goodman) introd. (Oscar Baylin Goodman; b. July 26, 1939, Philadelphia; attorney; mayor of Las Vegas, Nev.)
				</marc:subfield>
			</marc:datafield>
		</marc:record>
	</marc:collection>
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