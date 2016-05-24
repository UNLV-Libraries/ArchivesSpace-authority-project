class MarcExportSettings < Sequel::Model(:marc_export_settings)
  include ASModel
  corresponds_to JSONModel(:marc_export_settings)

  set_model_scope :repository

  def self.init
	defs_file = File.join(File.dirname(__FILE__), '..', '..', "config", "marc_export_settings_m_export_settings.rb")
    m_export_settings = {}
	
    if File.exists?(defs_file)
      found_defs_file = true
      Log.info("Loading m_export_settings file at #{defs_file}")
      m_export_settings = eval(File.read(defs_file))
    end

    RequestContext.in_global_repo do
      filter = {:repo_id => Repository.global_repo_id, :marc_export_user_id => nil}
      if self.filter(filter).count == 0
        Log.info("Creating system marc export settings")
        MarcExportSettings.create_from_json(JSONModel(:marc_export_settings).from_hash({
                                                                       :marc_export_user_id => nil,
                                                                       :m_export_settings => m_export_settings
                                                                     }),
                                    :repo_id => Repository.global_repo_id)
      else
        if found_defs_file
          Log.info("Updating system marc export settings")
          pref = self.filter(filter).first
          pref.update_from_json(JSONModel(:marc_export_settings).from_hash({:m_export_settings => m_export_settings}),
                                :lock_version => pref.lock_version)
        end
      end
    end    
  end
	
  def before_save
    super
    self.user_uniq = self.marc_export_user_id || 'GLOBAL_USER'
  end


  def after_save
    Notifications.notify("REFRESH_MARC_EXPORT_SETTINGS")
  end


  def parsed_m_export_settings
    ASUtils.json_parse(self.m_export_settings)
  end


  def self.parsed_m_export_settings_for(filter)
    pref = self[filter.merge(:repo_id => RequestContext.get(:repo_id))]
    pref ? pref.parsed_m_export_settings : {}
  end


  def self.global_m_export_settings
    RequestContext.open(:repo_id => Repository.global_repo_id) do
      self.parsed_m_export_settings_for(:marc_export_user_id => nil)
    end
  end


  def self.user_global_m_export_settings
    RequestContext.open(:repo_id => Repository.global_repo_id) do
      if RequestContext.get(:current_username)
        user_defs = self.parsed_m_export_settings_for(:marc_export_user_id => User[:username => RequestContext.get(:current_username)].id)
        self.global_m_export_settings.merge(user_defs)
      else
        self.global_m_export_settings
      end
    end
  end


  def self.repo_m_export_settings
    self.user_global_m_export_settings.merge(self.parsed_m_export_settings_for(:marc_export_user_id => nil))
  end


  def self.m_export_settings
    if RequestContext.get(:current_username)
      user_defs = self.parsed_m_export_settings_for(:marc_export_user_id => User[:username => RequestContext.get(:current_username)].id)
      self.repo_m_export_settings.merge(user_defs)
    else
      self.repo_m_export_settings
    end
  end


  def self.current_marc_export_settings(repo_id = RequestContext.get(:repo_id))
    return {} unless RequestContext.get(:current_username)

    marc_export_user_id = User[:username => RequestContext.get(:current_username)].id
    filter = {:repo_id => repo_id, :user_uniq => [marc_export_user_id.to_s, 'GLOBAL_USER']}
    json_prefs = {'m_export_settings' => {}}
    prefs = {}
    m_export_settings = {}

    if repo_id != Repository.global_repo_id
      self.filter(filter).each do |pref|
        if pref.user_uniq == 'GLOBAL_USER'
          json_prefs['repo'] = self.to_jsonmodel(pref)
          prefs[:repo] = pref
        else
          json_prefs['user_repo'] = self.to_jsonmodel(pref)
          prefs[:user_repo] = pref
        end
      end
    end

    RequestContext.in_global_repo do
      filter = {:repo_id => Repository.global_repo_id, :user_uniq => [marc_export_user_id.to_s, 'GLOBAL_USER']}
      self.filter(filter).each do |pref|
        if pref.user_uniq == 'GLOBAL_USER'
          json_prefs['global'] = self.to_jsonmodel(pref)
          prefs[:global] = pref
        else
          json_prefs['user_global'] = self.to_jsonmodel(pref)
          prefs[:user_global] = pref
        end
      end
    end

    [:global, :user_global, :repo, :user_repo].each do |k|
      if prefs[k]
        json_prefs['m_export_settings'].merge!(prefs[k].parsed_m_export_settings)
        json_prefs["m_export_settings_#{k}"] = json_prefs['m_export_settings'].clone
      end
    end
    json_prefs['m_export_settings'].delete('jsonmodel_type')

    json_prefs
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['m_export_settings'] = JSONModel(:m_export_settings).from_json(obj.m_export_settings)
    end

    jsons
  end


  def self.create_from_json(json, opts = {})
    super(json, opts.merge('m_export_settings' => JSON(json.m_export_settings || {})))
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    super(json, opts.merge('m_export_settings' => JSON(json.m_export_settings)),
          apply_nested_records)
  end

end