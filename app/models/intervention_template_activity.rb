class InterventionTemplateActivity < ActiveRecord::Base
  belongs_to :intervention_template
  belongs_to :activity

  attr_accessor :activity_label

  def attributes
    super.merge(activity_label: activity.name)
  end
end
