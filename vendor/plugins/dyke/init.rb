# Include hook code here
require 'dyta'
require 'dyli'

ActionController::Base.send(:include, ActionView::Helpers::AssetTagHelper)
ActionController::Base.send(:include, ActionView::Helpers::TextHelper)
ActionController::Base.send(:include, ActionView::Helpers::TagHelper)
ActionController::Base.send(:include, ActionView::Helpers::UrlHelper)

# initialization of the plugin Dyta.
ActionController::Base.send(:include, Dyta::Controller)
ActionView::Base.send(:include, Dyta::View)

# initialization of the plugin Dyli.
ActionController::Base.send(:include, Dyli::Controller)
ActionView::Base.send(:include, Dyli::View)
