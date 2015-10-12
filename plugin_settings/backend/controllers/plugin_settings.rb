class ArchivesSpaceService < Sinatra::Base

	Endpoint.post('/repositories/:repo_id/plugin_settings')
		.description("Provides summary reports on accessions")
		.params(["ead_loc_text", String, "EAD finding location text"],
				["repo_id", :repo_id])
		.permissions([])
		.returns([200, :created],
				 [400, :error]) \
	do
		save_settings(params)
	end

	private
	
	def save_settings(params)
		DB.open do |db|
			ds = db[:plugin_setting]
				.select(:ead_loc_text)
				.filter(:repo_id => params[:repo_id])
			
			ds.update(:ead_loc_text => params[:ead_loc_text])
		end	
	end
end
			
