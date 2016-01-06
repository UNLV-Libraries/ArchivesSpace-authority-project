require 'logger'
MarcXMLBaseMap.module_eval do
    # agents from 100 and 700 field are creators or sources
	  def creators_and_sources
		{
			
		  :map => {
			"subfield[@code='d']" => :dates,  
			"subfield[@code='e']" => -> agent, node {
			  agent['_role'] = case
							   when ['Auctioneer (auc)',
									 'Bookseller (bsl)',
									 'Collector (col)',
									 'Depositor (dpt)',
									 'Donor (dnr)',
									 'Former owner (fmo)',
									 'Funder (fnd)',
									 'Owner (own)'].include?(node.inner_text)
								'source'
							   else
								'creator'
							   end
			},
			"self::datafield" => {
			  :map => {
				"//controlfield[@tag='001']" => :authority_id, 
				"@ind1" => sets_name_order_from_ind1,
				"subfield[@code='v']" => adds_prefixed_qualifier('Form subdivision'),
				"subfield[@code='x']" => adds_prefixed_qualifier('General subdivision'),
				"subfield[@code='y']" => adds_prefixed_qualifier('Chronological subdivision'),
				"subfield[@code='z']" => adds_prefixed_qualifier('Geographic subdivision'),
			  },
			  :defaults => {
				:source => 'ingest',
			  }
			}
		  }
		}
	  end
end