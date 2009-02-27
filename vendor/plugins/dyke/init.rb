# Include hook code here
require 'dyta'
ActionController::Base.send(:include, ActionView::Helpers::AssetTagHelper)
ActionController::Base.send(:include, ActionView::Helpers::TextHelper)
ActionController::Base.send(:include, ActionView::Helpers::TagHelper)
ActionController::Base.send(:include, ActionView::Helpers::UrlHelper)
ActionController::Base.send(:include, Dyta::Controller)
ActionView::Base.send(:include, Dyta::View)
