class Mandate < ActiveRecord::Base
  belongs_to :entity
  belongs_to :company
  attr_readonly :company_id

  # def before_validation_on_create
#     self.started_on = Date.today
#     self.stopped_on = self.started_on
#   end
  
  
end
