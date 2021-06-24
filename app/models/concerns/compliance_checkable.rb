# frozen_string_literal: true

module ComplianceCheckable
  extend ActiveSupport::Concern

  included do
    scope :of_vendor_compliance, ->(vendor) { where("(compliance ->> 'vendor') = ?", vendor) }
    scope :of_compliance_name, ->(vendor, name) { of_vendor_compliance(vendor).where("(compliance ->> 'name') = ?", name) }

    scope :of_compliance_data, ->(key, value) { where("compliance -> 'data' ->> ? = ?", key, value) }
    scope :with_compliance_errors, ->(vendor, name) { of_compliance_name(vendor, name).where("(compliance -> 'data' ->> 'errors') != ?", '[]') }
    scope :with_compliance_error, ->(vendor, name, error) { of_compliance_name(vendor, name).where("(compliance -> 'data' ->> 'errors') ~ ?", error) }

    prepend Prepended
  end

  module Prepended
    def compliance_data
      compliance.fetch(:data, {})
    end

    def compliance
      super.with_indifferent_access
    end

    def compliance=(value)
      @compliance = super(value&.slice(:vendor, :name, :data))
    end

    def compliance_vendor
      compliance[:vendor]
    end

    def compliance_name
      compliance[:name]
    end

    def compliance_errors
      compliance_data[:errors] || []
    end

    def has_compliance_for?(vendor:, name:)
      (vendor == compliance_vendor) && (name == compliance_name)
    end
  end
end
