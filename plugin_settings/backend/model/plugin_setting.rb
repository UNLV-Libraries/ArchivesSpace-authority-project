class PluginSetting < Sequel::Model(:plugin_setting)
	include ASModel
	
	set_model_scope :global
	corresponds_to JSONModel(:plugin_setting)

end