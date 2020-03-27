# This module provides tools to use customs fields and expect model has a
# column +custom_fields+ (with JSONB type)
# TODO manage date types
module Customizable
  extend ActiveSupport::Concern

  included do
    # serialize :custom_fields

    # FIXME: Message doesn't appear in form...
    # validate :validate_custom_fields
  end

  # Returns the value of given custom_field
  def custom_value(field)
    return nil unless custom_fields
    custom_fields[field.column_name]
  end

  def set_custom_value(field, value)
    self.custom_fields ||= {}
    self.custom_fields[field.column_name] = value
  end

  def validate_custom_fields
    self.class.custom_fields.each do |custom_field|
      value = custom_value(custom_field)
      if value.blank?
        errors.add(:custom_fields, :blank, attribute: custom_field.name) if custom_field.required?
      else
        if custom_field.text?
          unless custom_field.maximal_length.blank? || custom_field.maximal_length <= 0
            errors.add(:custom_fields, :too_long, attribute: custom_field.name, count: custom_field.maximal_length) if value.length > custom_field.maximal_length
          end
          unless custom_field.minimal_length.blank? || custom_field.minimal_length <= 0
            errors.add(:custom_fields, :too_short, attribute: custom_field.name, count: custom_field.maximal_length) if value.length < custom_field.minimal_length
          end
        elsif custom_field.decimal?
          value = value.to_d unless value.is_a?(Numeric)
          if custom_field.minimal_value.present?
            errors.add(:custom_fields, :greater_than, attribute: custom_field.name, count: custom_field.minimal_value) if value < custom_field.minimal_value
          end
          if custom_field.maximal_value.present?
            errors.add(:custom_fields, :less_than, attribute: custom_field.name, count: custom_field.maximal_value) if value > custom_field.maximal_value
          end
        end
      end
    end
  end

  module ClassMethods
    # Returns the definition of custom fields of the class
    def custom_fields
      fields_id = self.ancestors
        .select { |a| a.ancestors.include? Customizable }
        .flat_map{ |k| CustomField.of(k.name) }
        .map(&:id)

      CustomField.where(id: fields_id)
    end
  end
end
