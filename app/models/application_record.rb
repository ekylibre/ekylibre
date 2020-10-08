class ApplicationRecord < ActiveRecord::Base
  prepend IdHumanizable

  self.abstract_class = true
end
