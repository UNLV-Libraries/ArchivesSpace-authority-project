ArchivesSpace::Application.routes.draw do
      resources :marc_export_settings
      match('/plugins/marc_export_settings/:id' => 'marc_export_settings#update', :via => [:post])
end