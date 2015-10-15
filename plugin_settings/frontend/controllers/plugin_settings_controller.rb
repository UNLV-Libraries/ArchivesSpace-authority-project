class PluginSettingsController < ApplicationController

  set_access_control  "view_repository" => [:index, :edit, :update]
  def index
	 redirect_to(:controller => :plugin_settings,
                  :action => :edit,
                  :id => 0,
				  :repo => true)
  end
  def edit
    scope = params['global'] ? 'global' : 'repo'
    user_prefix = params['repo'] ? '' : 'user_'
    @current_settings, global_repo_id = current_plugin_settings
    @settings = @current_settings['settings']
    level = "#{user_prefix}#{scope}"
    @inherited_settings = @current_settings["settings_global"]
    ['user_global', 'repo', 'user_repo'].each do |lev|
      break if lev == level
      @inherited_settings = @current_settings["settings_#{lev}"] if @current_settings["settings_#{lev}"]
    end
    opts = {}
    if params['global']
      opts[:repo_id] = global_repo_id
    end

    if @current_settings["#{user_prefix}#{scope}"]
      setting = JSONModel(:plugin_settings).from_hash(@current_settings["#{user_prefix}#{scope}"])
    else
      setting = JSONModel(:plugin_settings).new({
                                          :settings => {},
                                          :user_id => params['repo'] ? nil : JSONModel(:user).id_for(session[:user_uri])
                                        })
      setting.save(opts)
    end

    if params['id'] == setting.id.to_s
      @plugin_settings = setting
    else
      redirect_to(:controller => :plugin_settings,
                  :action => :edit,
                  :id => setting.id,
                  :global => params['global'],
                  :repo => params['repo'])
    end
  end


  def update
    prefs, global_repo_id = current_plugin_settings
    opts = {}
    opts[:repo_id] = global_repo_id if params['global']
    handle_crud(:instance => :plugin_settings,
                :model => JSONModel(:plugin_settings),
                :obj => JSONModel(:plugin_settings).find(params['id'], opts),
                :find_opts => opts,
                :save_opts => opts,
                :replace => false,
                :on_invalid => ->(){
                  return render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("plugins.plugin_settings._frontend.messages.updated",
                                           JSONModelI18nWrapper.new(:plugin_settings => @setting))
                  redirect_to(:controller => :plugin_settings,
                              :action => :edit,
                              :id => id,
                              :global => params['global'],
                              :repo => params['repo'])
                })
  end


  private

  def current_plugin_settings
    if session[:repo_id]
      current_settings = JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/current_plugin_settings")
    else
      current_settings = JSONModel::HTTP::get_json("/current_global_plugin_settings")
    end
	
     repo_id = JSONModel(:repository).id_for(current_settings['global']['repository']['ref'])
    return current_settings, repo_id
  end

end