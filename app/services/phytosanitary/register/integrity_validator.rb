# frozen_string_literal: true

module Phytosanitary
  module Register
    class IntegrityValidator
      MANDATORY_FIELDS = %i[
        holder_siret
        product_name
        amm_number
        application_date
        dose_value
        dose_unit
        treated_area_value
        crop_name
        location_geometry
      ].freeze

      Result = Struct.new(:errors_by_entry, keyword_init: true) do
        def ok?
          errors_by_entry.empty?
        end

        def total_errors
          errors_by_entry.values.sum(&:size)
        end
      end

      def self.call(payload)
        new(payload).call
      end

      def initialize(payload)
        @payload = payload
      end

      def call
        errors = {}
        @payload.entries.to_a.each do |entry|
          missing = missing_fields(entry)
          errors[entry_key(entry)] = missing unless missing.empty?
        end
        Result.new(errors_by_entry: errors)
      end

      private

        def missing_fields(entry)
          MANDATORY_FIELDS.reject { |f| present?(entry[f]) }
        end

        def present?(value)
          return false if value.nil?
          return false if value.respond_to?(:empty?) && value.empty?

          true
        end

        def entry_key(entry)
          [entry.intervention_id, entry.intervention_input_id, entry.intervention_target_id]
        end
    end
  end
end
