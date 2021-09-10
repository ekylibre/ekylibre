# frozen_string_literal: true

class InterventionTemplateActivity < ApplicationRecord
  belongs_to :intervention_template, class_name: ::InterventionTemplate
  belongs_to :activity, class_name: ::Activity

  validates :activity, uniqueness: { scope: :intervention_template }

  attr_accessor :activity_label

  def attributes
    super.merge(activity_label: activity&.name)
  end
end
