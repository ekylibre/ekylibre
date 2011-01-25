ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: 
  # first created -> highest priority.

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':company/:controller/:action/:id.:format'
  map.connect ':company/:controller/:action/:id'
  map.connect ':company/:controller/:action.:format'
  map.connect ':company', :controller=>"company"
  map.connect ':controller/:action', :controller=>'company', :action=>'index'
  # map.connect '*path', :controller=>"company", :action=>"unknown_action"
  map.connect 'authentication/:action', :controller=>'authentication', :action=>/(login|register)/
  map.connect 'application/:action', :controller=>'application'

  map.root :controller => "company"
end
