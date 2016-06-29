Rails.application.config.after_initialize do

    SearchResultData.class_eval do
	
		#include IdentifierFilter
		def self.ACCESSION_FACETS
		 ["subjects", "accession_date_year","id_0_u_sstr","creators"]
		end
    end
	
end