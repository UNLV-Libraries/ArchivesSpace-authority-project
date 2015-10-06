class MARCModel < ASpaceExport::ExportModel
	model_for :marc21
	
	include JSONModel
	
    def handle_id(*ids)
		ids.reject!{|i| i.nil? || i.empty?}
		df('099', ' ', ' ').with_sfs(['a', ids.join('-')])
		#connect using a hyphen instead of period
		df('852', ' ', ' ').with_sfs(['c', ids.join('-')])
	end
	
end