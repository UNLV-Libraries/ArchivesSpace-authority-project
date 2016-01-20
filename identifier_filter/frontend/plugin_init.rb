Rails.application.config.after_initialize do

    SearchResultData.class_eval do
	
		#include IdentifierFilter
		def self.ACCESSION_FACETS
		 ["subjects", "accession_date_year","id_0_u_sstr","creators"]
		end
		#class << SearchResultData
			#alias_method :ACCESSION_FACETS, :fixed
		##	def fixed
		#	 ["subjects", "accession_date_year", "accession_id", "source" ,"creators"]
		#	end
		#end
    end
	
end