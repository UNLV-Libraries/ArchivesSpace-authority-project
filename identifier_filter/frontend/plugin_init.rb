Rails.application.config.after_initialize do

    SearchResultData.class_eval do
	
		#include IdentifierFilter
		def self.ACCESSION_FACETS
		 ["subjects", "accession_date_year","id_0_u_sstr","creators"]
		end
		
		#include IdentifierFilter
		def self.RESOURCE_FACETS
		 ["subjects", "publish", "level", "classification_path", "primary_type","id_0_u_sstr","id_1_u_sstr"]
		end
    end
	
end