class SpawnSettingsController < ApplicationController

  set_access_control "manage_repository" => [:index, :edit, :update]
									
  def index
	 redirect_to(:controller => :spawn_settings,
                  :action => :edit,
                  :id => 0,
				  :repo=> true)
  end
  def edit
    scope = params['global'] ? 'global' : 'repo'
    user_prefix = params['repo'] ? '' : 'user_'
    @current_settings, global_repo_id = current_spawn_settings
    @settings = @current_settings['settings']
    level = "#{user_prefix}#{scope}"
    @inherited_settings = @current_settings["spawn_defaults_global"]
    ['user_global', 'repo', 'user_repo'].each do |lev|
      break if lev == level
      @inherited_settings = @current_settings["spawn_defaults_#{lev}"] if @current_settings["spawn_defaults_#{lev}"]
    end
    opts = {}
    if params['global']
      opts[:repo_id] = global_repo_id
    end


    if @current_settings["#{user_prefix}#{scope}"]
      spawn_defaults = JSONModel(:spawn_settings).from_hash(@current_settings["#{user_prefix}#{scope}"])
    else
      spawn_defaults = JSONModel(:spawn_settings).new({
											:spawn_defaults => {},
											:spawn_user_id => params['repo'] ? nil : JSONModel(:user).id_for(session[:user_uri])
                                        })
      spawn_defaults.save(opts)
    end

    if params['id'] == spawn_defaults.id.to_s
      @spawn_settings = spawn_defaults
    else
      redirect_to(:controller => :spawn_settings,
                  :action => :edit,
                  :id => spawn_defaults.id,
                  :repo => params['repo'])
    end
  end


  def update
     prefs, global_repo_id = current_spawn_settings
     opts = {}
     opts[:repo_id] = global_repo_id if params['global']
     handle_crud(:instance => :spawn_settings,
                 :model => JSONModel(:spawn_settings),
                 :obj => JSONModel(:spawn_settings).find(params['id'], opts),
                 :find_opts => opts,
                 :save_opts => opts,
                 :replace => false,
                 :on_invalid => ->(){
                  return render action: "edit"
                 },
                 :on_valid => ->(id){
                   flash[:success] = I18n.t("plugins.spawn_settings._frontend.messages.updated",
                                            JSONModelI18nWrapper.new(:spawn_settings => @spawn_settings))
                   redirect_to(:controller => :spawn_settings,
                               :action => :edit,
                               :id => id,
                               :global => params['global'],
                               :repo => params['repo'])
                 })
  end


  private

  def current_spawn_settings
    if session[:repo_id]
      current_settings = JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/current_spawn_settings")
    else
      current_settings = JSONModel::HTTP::get_json("/current_global_spawn_settings")
    end
	
     repo_id = JSONModel(:repository).id_for(current_settings['global']['repository']['ref'])
    return current_settings, repo_id
  end

end