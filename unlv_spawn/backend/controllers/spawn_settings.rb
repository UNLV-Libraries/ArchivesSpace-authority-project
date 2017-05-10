class ArchivesSpaceService < Sinatra::Base

	Endpoint.post('/repositories/:repo_id/spawn_settings')
		.description("Create a spawn record")
		.params(["spawn_settings", JSONModel(:spawn_settings), "The spawn settings record to create", :body => true],
				["repo_id", :repo_id])
		.permissions([:manage_repository])
		.returns([200, :created],
				 [400, :error]) \
	do
		 check_marc_permissions(params)
		 handle_create(SpawnSettings, params[:spawn_settings])
	end
	
	Endpoint.get('/repositories/:repo_id/spawn_settings/spawn_defaults')
		.description("Get the default set of spawn settings for a Repository and optionally a user")
		.params(["repo_id", :repo_id],
				["username", String, "The username to retrieve settings for", :optional => true])
		.permissions([])
		.returns([200, "(spawn_defaults)"]) \
    do
	 	json_response(SpawnSettings.settings_for(params[:repo_id], params[:username]))
	end
	
	Endpoint.get('/repositories/:repo_id/spawn_settings/:id')
		.description("Get a spawn settings record")
		.params(["id", :id],
				["repo_id", :repo_id])
		.permissions([])
		.returns([200, "(:spawn_settings)"]) \
	do
		json = SpawnSettings.to_jsonmodel(params[:id])

		json_response(json)
	end
	
	Endpoint.get('/repositories/:repo_id/current_spawn_settings')
      .description("Get the spawn settings records for the current repository and user.")
      .params(["repo_id", :repo_id])
      .permissions([])
      .returns([200, "{(:spawn_settings)}"]) \
    do
      json = SpawnSettings.current_spawn_settings(params[:repo_id])
   
      json_response(json)
    end
	
	Endpoint.get('/current_global_spawn_settings')
      .description("Get the global spawn settings records for the current user.")
      .params()
      .permissions([])
      .returns([200, "{(:spawn_settings)}"]) \
    do
      json = SpawnSettings.current_spawn_settings(Repository.global_repo_id)
   
      json_response(json)
    end
	
	Endpoint.post('/repositories/:repo_id/spawn_settings/:id')
      .description("Update a spawn settings record")
      .params(["id", :id],
              ["spawn_settings", JSONModel(:spawn_settings), "The updated record", :body => true],
              ["repo_id", :repo_id])
      .permissions([])
      .returns([200, :updated],
               [400, :error]) \
    do
      check_marc_permissions(params)
      handle_update(SpawnSettings, params[:id], params[:spawn_settings])
    end


    Endpoint.get('/repositories/:repo_id/spawn_settings')
      .description("Get a list of spawn settings for a Repository and optionally a user")
      .params(["repo_id", :repo_id],
              ["spawn_user_id", Integer, "The username to retrieve settings for", :optional => true])
      .permissions([:view_repository])
      .returns([200, "[(:spawn_settings)]"]) \
    do
      handle_unlimited_listing(SpawnSettings, params)
    end


    Endpoint.delete('/repositories/:repo_id/spawn_settings/:id')
      .description("Delete a spawn settings record")
      .params(["id", :id],
              ["repo_id", :repo_id])
      .permissions([:delete_archival_record])
      .returns([200, :deleted]) \
    do
      check_marc_permissions(params)
      handle_delete(SpawnSettings, params[:id])
    end


    def check_marc_permissions(params)
      if (params.has_key?(:spawn_settings))
        spawn_user_id = params[:spawn_settings]['spawn_user_id']
        repo_id = params[:spawn_settings]['repo_id']
      else
        spawn_user_id = SpawnSettings[params[:id]].spawn_user_id
        repo_id = params[:repo_id]
      end
    
      # trying to edit global prefs
      if spawn_user_id.nil? &&
          repo_id == Repository.global_repo_id &&
          !current_user.can?(:administer_system)
        raise AccessDeniedException.new
      end
    
      # trying to edit repo prefs
      if spawn_user_id.nil? &&
          !current_user.can?(:manage_repository)
        raise AccessDeniedException.new
      end
    
      # trying to edit user prefs
      if spawn_user_id && spawn_user_id != current_user.id
        raise AccessDeniedException.new
      end
    end

end		