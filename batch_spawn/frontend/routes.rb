ArchivesSpace::Application.routes.draw do
		
      match('/plugins/batch_spawn' => 'batch_spawn#index', :via => [:get])
      match('/plugins/batch_spawn' => 'batch_spawn#batch_spawn', :via => [:post])
      match('/plugins/batch_spawn' => 'batch_spawn#spawn', :via => [:post])
      match('/plugins/batch_spawn' => 'batch_spawn#create', :via => [:post])
end