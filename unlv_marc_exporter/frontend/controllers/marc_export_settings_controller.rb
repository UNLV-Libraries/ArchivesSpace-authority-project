class MarcExportSettingsController < ApplicationController

  set_access_control "manage_repository" => [:index, :edit, :update]
									
  def index
	 redirect_to(:controller => :marc_export_settings,
                  :action => :edit,
                  :id => 0,
				  :repo=> true)
  end
  def edit
    scope = params['global'] ? 'global' : 'repo'
    user_prefix = params['repo'] ? '' : 'user_'
    @current_settings, global_repo_id = current_marc_export_settings
    @settings = @current_settings['settings']
    level = "#{user_prefix}#{scope}"
    @inherited_settings = @current_settings["m_export_settings_global"]
    ['user_global', 'repo', 'user_repo'].each do |lev|
      break if lev == level
      @inherited_settings = @current_settings["m_export_settings_#{lev}"] if @current_settings["m_export_settings_#{lev}"]
    end
    opts = {}
    if params['global']
      opts[:repo_id] = global_repo_id
    end


    if @current_settings["#{user_prefix}#{scope}"]
      m_export_settings = JSONModel(:marc_export_settings).from_hash(@current_settings["#{user_prefix}#{scope}"])
    else
      m_export_settings = JSONModel(:marc_export_settings).new({
											:m_export_settings => {},
											:marc_export_user_id => params['repo'] ? nil : JSONModel(:user).id_for(session[:user_uri])
                                        })
      m_export_settings.save(opts)
    end

    if params['id'] == m_export_settings.id.to_s
      @marc_export_settings = m_export_settings
    else
      redirect_to(:controller => :marc_export_settings,
                  :action => :edit,
                  :id => m_export_settings.id,
                  :repo => params['repo'])
    end
  end


  def update
     prefs, global_repo_id = current_marc_export_settings
     opts = {}
     opts[:repo_id] = global_repo_id if params['global']
     handle_crud(:instance => :marc_export_settings,
                 :model => JSONModel(:marc_export_settings),
                 :obj => JSONModel(:marc_export_settings).find(params['id'], opts),
                 :find_opts => opts,
                 :save_opts => opts,
                 :replace => false,
                 :on_invalid => ->(){
                  return render action: "edit"
                 },
                 :on_valid => ->(id){
                   flash[:success] = I18n.t("plugins.marc_export_settings._frontend.messages.updated",
                                            JSONModelI18nWrapper.new(:marc_export_settings => @marc_export_settings))
                   redirect_to(:controller => :marc_export_settings,
                               :action => :edit,
                               :id => id,
                               :global => params['global'],
                               :repo => params['repo'])
                 })
  end


  private

  def current_marc_export_settings
    if session[:repo_id]
      current_settings = JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/current_marc_export_settings")
    else
      current_settings = JSONModel::HTTP::get_json("/current_global_marc_export_settings")
    end
	
     repo_id = JSONModel(:repository).id_for(current_settings['global']['repository']['ref'])
    return current_settings, repo_id
  end

end