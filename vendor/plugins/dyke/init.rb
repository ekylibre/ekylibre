# require 'dyta'
require 'dyli'
# require 'manage'

# ActionController::Base.send(:include, ActionView::Helpers::AssetTagHelper)
# ActionController::Base.send(:include, ActionView::Helpers::TextHelper)
# ActionController::Base.send(:include, ActionView::Helpers::TagHelper)
# ActionController::Base.send(:include, ActionView::Helpers::UrlHelper)
# ActionController::Base.send(:include, ActionView::Helpers::NumberHelper)
# ActionController::Base.send(:include, WillPaginate::ViewHelpers) if Ekylibre::Dyke::Dyta.will_paginate

# Initialization of the feature Dyta.
# ActionController::Base.send(:include, Ekylibre::Dyke::Dyta::Controller)
# ActionView::Base.send(:include, Ekylibre::Dyke::Dyta::View)

# Initialization of the feature Dyli.
ActionController::Base.send(:include, Ekylibre::Dyke::Dyli::Controller)
ActionView::Base.send(:include, Ekylibre::Dyke::Dyli::View)

# Initialization of the feature Manage.
# ActionController::Base.send(:include, Ekylibre::Dyke::Manage::Controller)

#ActionController::Base.send(:include, Ekylibre::Dyke::Dyse::Controller)
#ActionView::Base.send(:include, Ekylibre::Dyke::Dyse::View)
