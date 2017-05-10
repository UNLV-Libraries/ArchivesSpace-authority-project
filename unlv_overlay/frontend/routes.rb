ArchivesSpace::Application.routes.draw do
		
      match('/plugins/overlay' => 'overlay#index', :via => [:get])
      match('/plugins/overlay/overlay' => 'overlay#overlay', :via => [:post])
end