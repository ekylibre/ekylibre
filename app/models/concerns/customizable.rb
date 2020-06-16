# frozen_string_literal: true

# This module provides tools to use customs fields and expect model has a
# column +custom_fields+ (with JSONB type)
# TODO manage date types
module Customizable
  extend ActiveSupport::Concern

  class CustomModel
    include Ekylibre::Model

    SETTER_REGEX = /\A.*?=\z/.freeze

    attr_reader :fields, :values
    
    # @param [Array<CustomField>] fields
    # @param [Hash{String => Object}] values
    def initialize(fields:, values: )
      @fields = fields
      @values = values
    end

    def attributes
      @values
    end

    def method_missing(method, *args)
      if method.to_s =~ SETTER_REGEX && (field = field_for_setter(method)).present?
        @values[field.column_name] = args.first
      elsif (field = field_for_attribute(method)).present?
        @values[field.column_name]
      else
        super
      end
    end

    def read_attribute_for_validation(attribute)
      @values[attributes.to_s]
    end

    private

      def field_for_setter(method)
        method = method.to_s
        field_for_attribute(method[0..-2])
      end

      def field_for_attribute(method)
        method = method.to_s
        @fields.detect { |f| f.column_name == method }
      end

      def respond_to_missing?(method, *)
        super || (method.to_s =~ SETTER_REGEX && field_for_setter(method).present?) || field_for_attribute(method).present?
      end
  end

  included do
    #serialize :custom_fields

    # FIXME: Message doesn't appear in form...
    validate :validate_custom_fields
  end

  def custom_fields_model
    @__custom_field_model ||= CustomModel.new(fields: self.class.custom_fields.to_a, values: custom_fields || {})
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
        custom_fields_model.errors.add(custom_field.column_name.to_sym, :blank, attribute: custom_field.name) if custom_field.required?
      else
        if custom_field.text?
          if custom_field.maximal_length.present? && custom_field.maximal_length > 0 && value.length > custom_field.maximal_length
            custom_fields_model.errors.add(custom_field.column_name.to_sym, :too_long, attribute: custom_field.name, count: custom_field.maximal_length)
          end
          unless custom_field.minimal_length.blank? || custom_field.minimal_length <= 0
            custom_fields_model.errors.add(custom_field.column_name.to_sym, :too_short, attribute: custom_field.name, count: custom_field.minimal_length) if value.length < custom_field.minimal_length
          end
        elsif custom_field.decimal?
          value = value.to_d unless value.is_a?(Numeric)
          if custom_field.minimal_value.present?
            custom_fields_model.errors.add(custom_field.column_name.to_sym, :greater_than, attribute: custom_field.name, count: custom_field.minimal_value) if value < custom_field.minimal_value
          end
          if custom_field.maximal_value.present?
            custom_fields_model.errors.add(custom_field.column_name.to_sym, :less_than, attribute: custom_field.name, count: custom_field.maximal_value) if value > custom_field.maximal_value
          end
        end
      end
    end
    if custom_fields_model.errors.any?
      errors.add(:custom_fields, "")
    end
  end

  private def add_custom_field_error(field, message, **options)
    custom_fields_model.errors.add(field, message, options)
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
