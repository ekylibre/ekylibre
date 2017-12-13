class InterventionTemplateActivity < ActiveRecord::Base
  belongs_to :intervention_template
  belongs_to :activity
end
