# Include hook code here
require 'dyta'
require 'dyli'

ActionController::Base.send(:include, ActionView::Helpers::AssetTagHelper)
ActionController::Base.send(:include, ActionView::Helpers::TextHelper)
ActionController::Base.send(:include, ActionView::Helpers::TagHelper)
ActionController::Base.send(:include, ActionView::Helpers::UrlHelper)
ActionController::Base.send(:include, WillPaginate::ViewHelpers)

# initialization of the plugin Dyta.
ActionController::Base.send(:include, Ekylibre::Dyke::Dyta::Controller)
ActionView::Base.send(:include, Ekylibre::Dyke::Dyta::View)

# initialization of the plugin Dyli.
ActionController::Base.send(:include, Ekylibre::Dyke::Dyli::Controller)
ActionView::Base.send(:include, Ekylibre::Dyke::Dyli::View)
