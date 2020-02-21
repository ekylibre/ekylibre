module Providable
  extend ActiveSupport::Concern

  included do
    scope :of_vendor_provider, -> (vendor) { where("(provider -> vendor) = ?", vendor) }
    scope :of_provider_name, -> (vendor, name) { of_vendor_provider(vendor).where("(provider -> name) = ?", name)}

    scope :of_provider, -> (vendor, name, id) { of_provider_name(vendor, name).where("(provider -> id) = ?", id)}

    prepend Prepended
  end

  module Prepended
    def provider_data=(data)
      self.provider[:data]= data
    end

    def provider_data
      self.provider.fetch(:data, {})
    end

    def provider=(value)
      super(value.slice(:vendor, :name, :id, :data))
    end

    def provider
      @provider ||= {}
    end

    def provider_vendor
      self.provider[:vendor]
    end

    def provider_name
      self.provider[:name]
    end

    def provider_id
      self.provider[:id]
    end

    def is_provided_by?(vendor:, name:, id: nil)
      vendor == self.provider_vendor && name == self.provider_name && (id.nil? || id == self.provider_id)
    end
  end
end
