class SpawnSettings < Sequel::Model(:spawn_settings)
  include ASModel
  corresponds_to JSONModel(:spawn_settings)

  set_model_scope :repository

  def self.init
	defs_file = File.join(File.dirname(__FILE__), '..', '..', "config", "spawn_settings_spawn_defaults.rb")
    spawn_defaults = {}
	
    if File.exists?(defs_file)
      found_defs_file = true
      Rails.logger.info("Loading spawn defualts file at #{defs_file}")
      spawn_defaults = eval(File.read(defs_file))
    end

    RequestContext.in_global_repo do
      filter = {:repo_id => Repository.global_repo_id, :spawn_user_id => nil}
      if self.filter(filter).count == 0
        Rails.logger.info("Creating system spawn settings")
        SpawnSettings.create_from_json(JSONModel(:spawn_settings).from_hash({
                                                                       :spawn_user_id => nil,
                                                                       :spawn_defaults => spawn_defaults
                                                                     }),
                                    :repo_id => Repository.global_repo_id)
      else
        if found_defs_file
          Rails.logger.info("Updating system spawn settings")
          pref = self.filter(filter).first
          pref.update_from_json(JSONModel(:spawn_settings).from_hash({:spawn_defaults => spawn_defaults}),
                                :lock_version => pref.lock_version)
        end
      end
    end    
  end
	
  def before_save
    super
    self.user_uniq = self.spawn_user_id || 'GLOBAL_USER'
  end


  def after_save
    Notifications.notify("REFRESH_spawn_settings")
  end


  def parsed_spawn_defaults
    ASUtils.json_parse(self.spawn_defaults)
  end


  def self.parsed_spawn_defaults_for(filter)
    pref = self[filter.merge(:repo_id => RequestContext.get(:repo_id))]
    pref ? pref.parsed_spawn_defaults : {}
  end


  def self.global_spawn_defaults
    RequestContext.open(:repo_id => Repository.global_repo_id) do
      self.parsed_spawn_defaults_for(:spawn_user_id => nil)
    end
  end


  def self.user_global_spawn_defaults
    RequestContext.open(:repo_id => Repository.global_repo_id) do
      if RequestContext.get(:current_username)
        user_defs = self.parsed_spawn_defaults_for(:spawn_user_id => User[:username => RequestContext.get(:current_username)].id)
        self.global_spawn_defaults.merge(user_defs)
      else
        self.global_spawn_defaults
      end
    end
  end


  def self.repo_spawn_defaults
    self.user_global_spawn_defaults.merge(self.parsed_spawn_defaults_for(:spawn_user_id => nil))
  end


  def self.spawn_defaults
    if RequestContext.get(:current_username)
      user_defs = self.parsed_spawn_defaults_for(:spawn_user_id => User[:username => RequestContext.get(:current_username)].id)
      self.repo_spawn_defaults.merge(user_defs)
    else
      self.repo_spawn_defaults
    end
  end


  def self.current_spawn_settings(repo_id = RequestContext.get(:repo_id))
    return {} unless RequestContext.get(:current_username)

    spawn_user_id = User[:username => RequestContext.get(:current_username)].id
    filter = {:repo_id => repo_id, :user_uniq => [spawn_user_id.to_s, 'GLOBAL_USER']}
    json_prefs = {'spawn_defaults' => {}}
    prefs = {}
    spawn_defaults = {}

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
      filter = {:repo_id => Repository.global_repo_id, :user_uniq => [spawn_user_id.to_s, 'GLOBAL_USER']}
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
        json_prefs['spawn_defaults'].merge!(prefs[k].parsed_spawn_defaults)
        json_prefs["spawn_defaults_#{k}"] = json_prefs['spawn_defaults'].clone
      end
    end
    json_prefs['spawn_defaults'].delete('jsonmodel_type')

    json_prefs
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['spawn_defaults'] = JSONModel(:spawn_defaults).from_json(obj.spawn_defaults)
    end

    jsons
  end


  def self.create_from_json(json, opts = {})
    super(json, opts.merge('spawn_defaults' => JSON(json.spawn_defaults || {})))
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    super(json, opts.merge('spawn_defaults' => JSON(json.spawn_defaults)),
          apply_nested_records)
  end

end