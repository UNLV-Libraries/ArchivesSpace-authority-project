class ArchivesSpaceService < Sinatra::Base

	Endpoint.post('/repositories/:repo_id/plugin_settings')
		.description("Create a Plugin Settings record")
		.params(["plugin_settings", JSONModel(:plugin_settings), "The plugin settings record to create", :body => true],
				["repo_id", :repo_id])
		.permissions([:manage_repository])
		.returns([200, :created],
				 [400, :error]) \
	do
	  Log.debug("update61aa2")
		 check_permissions(params)
		 handle_create(PluginSettings, params[:plugin_settings])
	end
	
	Endpoint.get('/repositories/:repo_id/plugin_settings/settings')
		.description("Get the default set of Plugin Settings for a Repository and optionally a user")
		.params(["repo_id", :repo_id],
				["username", String, "The username to retrieve settings for", :optional => true])
		.permissions([])
		.returns([200, "(settings)"]) \
    do
	  Log.debug("update61a2")
	 	json_response(PluginSettings.settings_for(params[:repo_id], params[:username]))
	end
	
	Endpoint.get('/repositories/:repo_id/plugin_settings/:id')
		.description("Get a Plugin Settings record")
		.params(["id", :id],
				["repo_id", :repo_id])
		.permissions([])
		.returns([200, "(:plugin_settings)"]) \
	do
	  Log.debug("update612")
		json = PluginSettings.to_jsonmodel(params[:id])

		json_response(json)
	end
	
	Endpoint.get('/repositories/:repo_id/current_plugin_settings')
      .description("Get the Plugin Settings records for the current repository and user.")
      .params(["repo_id", :repo_id])
      .permissions([])
      .returns([200, "{(:plugin_settings)}"]) \
    do
	  Log.debug("update68")
      json = PluginSettings.current_plugin_settings(params[:repo_id])
   
      json_response(json)
    end
	
	Endpoint.get('/current_global_plugin_settings')
      .description("Get the global Plugin Settings records for the current user.")
      .params()
      .permissions([])
      .returns([200, "{(:plugin_settings)}"]) \
    do
	  Log.debug("update6")
      json = PluginSettings.current_plugin_settings(Repository.global_repo_id)
   
      json_response(json)
    end
	
	Endpoint.post('/repositories/:repo_id/plugin_settings/:id')
      .description("Update a Plugin Settings record")
      .params(["id", :id],
              ["plugin_settings", JSONModel(:plugin_settings), "The updated record", :body => true],
              ["repo_id", :repo_id])
      .permissions([])
      .returns([200, :updated],
               [400, :error]) \
    do
	  Log.debug("update")
      check_permissions(params)
      handle_update(PluginSettings, params[:id], params[:plugin_settings])
    end


    Endpoint.get('/repositories/:repo_id/plugin_settings')
      .description("Get a list of Plugin Settings for a Repository and optionally a user")
      .params(["repo_id", :repo_id],
              ["user_id", Integer, "The username to retrieve settings for", :optional => true])
      .permissions([:view_repository])
      .returns([200, "[(:plugin_settings)]"]) \
    do
	  Log.debug("update1")
      handle_unlimited_listing(PluginSettings, params)
    end


    Endpoint.delete('/repositories/:repo_id/plugin_settings/:id')
      .description("Delete a Plugin Settings record")
      .params(["id", :id],
              ["repo_id", :repo_id])
      .permissions([:delete_archival_record])
      .returns([200, :deleted]) \
    do
	  Log.debug("delete")
      check_permissions(params)
      handle_delete(PluginSettings, params[:id])
    end


    def check_permissions(params)
      if (params.has_key?(:plugin_settings))
        user_id = params[:plugin_settings]['user_id']
        repo_id = params[:plugin_settings]['repo_id']
      else
        user_id = PluginSettings[params[:id]].user_id
        repo_id = params[:repo_id]
      end
    
      # trying to edit global prefs
      if user_id.nil? &&
          repo_id == Repository.global_repo_id &&
          !current_user.can?(:administer_system)
        raise AccessDeniedException.new
      end
    
      # trying to edit repo prefs
      if user_id.nil? &&
          !current_user.can?(:manage_repository)
        raise AccessDeniedException.new
      end
    
      # trying to edit user prefs
      if user_id && user_id != current_user.id
        raise AccessDeniedException.new
      end
    end

end
			
