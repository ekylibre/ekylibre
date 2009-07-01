require 'dyta'
require 'dyli'

ActionController::Base.send(:include, ActionView::Helpers::AssetTagHelper)
ActionController::Base.send(:include, ActionView::Helpers::TextHelper)
ActionController::Base.send(:include, ActionView::Helpers::TagHelper)
ActionController::Base.send(:include, ActionView::Helpers::UrlHelper)
ActionController::Base.send(:include, WillPaginate::ViewHelpers) if defined? WillPaginate

# Initialization of the plugin Dyta.
ActionController::Base.send(:include, Ekylibre::Dyke::Dyta::Controller)
ActionView::Base.send(:include, Ekylibre::Dyke::Dyta::View)

# Initialization of the plugin Dyli.
ActionController::Base.send(:include, Ekylibre::Dyke::Dyli::Controller)
ActionView::Base.send(:include, Ekylibre::Dyke::Dyli::View)

