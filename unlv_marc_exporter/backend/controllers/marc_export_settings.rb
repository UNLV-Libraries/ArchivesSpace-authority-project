class ArchivesSpaceService < Sinatra::Base

	Endpoint.post('/repositories/:repo_id/marc_export_settings')
		.description("Create a Marc Export record")
		.params(["marc_export_settings", JSONModel(:marc_export_settings), "The marc export settings record to create", :body => true],
				["repo_id", :repo_id])
		.permissions([:manage_repository])
		.returns([200, :created],
				 [400, :error]) \
	do
		 check_permissions(params)
		 handle_create(MarcExportSettings, params[:marc_export_settings])
	end
	
	Endpoint.get('/repositories/:repo_id/marc_export_settings/m_export_settings')
		.description("Get the default set of marc export settings for a Repository and optionally a user")
		.params(["repo_id", :repo_id],
				["username", String, "The username to retrieve settings for", :optional => true])
		.permissions([])
		.returns([200, "(m_export_settings)"]) \
    do
	 	json_response(MarcExportSettings.settings_for(params[:repo_id], params[:username]))
	end
	
	Endpoint.get('/repositories/:repo_id/marc_export_settings/:id')
		.description("Get a marc export settings record")
		.params(["id", :id],
				["repo_id", :repo_id])
		.permissions([])
		.returns([200, "(:marc_export_settings)"]) \
	do
		json = MarcExportSettings.to_jsonmodel(params[:id])

		json_response(json)
	end
	
	Endpoint.get('/repositories/:repo_id/current_marc_export_settings')
      .description("Get the marc export settings records for the current repository and user.")
      .params(["repo_id", :repo_id])
      .permissions([])
      .returns([200, "{(:marc_export_settings)}"]) \
    do
      json = MarcExportSettings.current_marc_export_settings(params[:repo_id])
   
      json_response(json)
    end
	
	Endpoint.get('/current_global_marc_export_settings')
      .description("Get the global marc export settings records for the current user.")
      .params()
      .permissions([])
      .returns([200, "{(:marc_export_settings)}"]) \
    do
      json = MarcExportSettings.current_marc_export_settings(Repository.global_repo_id)
   
      json_response(json)
    end
	
	Endpoint.post('/repositories/:repo_id/marc_export_settings/:id')
      .description("Update a marc export settings record")
      .params(["id", :id],
              ["marc_export_settings", JSONModel(:marc_export_settings), "The updated record", :body => true],
              ["repo_id", :repo_id])
      .permissions([])
      .returns([200, :updated],
               [400, :error]) \
    do
      check_permissions(params)
      handle_update(MarcExportSettings, params[:id], params[:marc_export_settings])
    end


    Endpoint.get('/repositories/:repo_id/marc_export_settings')
      .description("Get a list of marc export settings for a Repository and optionally a user")
      .params(["repo_id", :repo_id],
              ["marc_export_user_id", Integer, "The username to retrieve settings for", :optional => true])
      .permissions([:view_repository])
      .returns([200, "[(:marc_export_settings)]"]) \
    do
	  Log.debug("update1")
      handle_unlimited_listing(MarcExportSettings, params)
    end


    Endpoint.delete('/repositories/:repo_id/marc_export_settings/:id')
      .description("Delete a marc export settings record")
      .params(["id", :id],
              ["repo_id", :repo_id])
      .permissions([:delete_archival_record])
      .returns([200, :deleted]) \
    do
	  Log.debug("delete")
      check_permissions(params)
      handle_delete(MarcExportSettings, params[:id])
    end


    def check_permissions(params)
      if (params.has_key?(:marc_export_settings))
        marc_export_user_id = params[:marc_export_settings]['marc_export_user_id']
        repo_id = params[:marc_export_settings]['repo_id']
      else
        marc_export_user_id = MarcExportSettings[params[:id]].marc_export_user_id
        repo_id = params[:repo_id]
      end
    
      # trying to edit global prefs
      if marc_export_user_id.nil? &&
          repo_id == Repository.global_repo_id &&
          !current_user.can?(:administer_system)
        raise AccessDeniedException.new
      end
    
      # trying to edit repo prefs
      if marc_export_user_id.nil? &&
          !current_user.can?(:manage_repository)
        raise AccessDeniedException.new
      end
    
      # trying to edit user prefs
      if marc_export_user_id && marc_export_user_id != current_user.id
        raise AccessDeniedException.new
      end
    end

end
			
