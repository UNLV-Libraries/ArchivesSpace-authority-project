ArchivesSpace::Application.routes.draw do
      resources :plugin_settings
      match('/plugins/plugin_settings/:id' => 'plugin_settings#update', :via => [:post])
end