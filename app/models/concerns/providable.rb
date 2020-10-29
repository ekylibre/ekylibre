module Providable
  extend ActiveSupport::Concern

  included do
    scope :of_vendor_provider, -> (vendor) { where("(provider ->> 'vendor') = ?", vendor) }
    scope :of_provider_name, -> (vendor, name) { of_vendor_provider(vendor).where("(provider ->> 'name') = ?", name)}

    scope :of_provider, -> (vendor, name, id) { of_provider_name(vendor, name).where("(provider ->> 'id') = ?", id.to_s)}

    scope :of_provider_data, ->(key, value) {  where("provider -> 'data' ->> ? = ?", key, value)}

    prepend Prepended
  end

  module Prepended

    # @param [Hash{Symbol => Object}] data
    def provider_data=(data)
      self.provider = {**provider, data: data}
    end

    # @return [Hash{Symbol => Object}]
    def provider_data
      self.provider.fetch(:data, {}).transform_keys(&:to_sym)
    end

    # @param [Hash{Symbol => String, Hash}] value
    def provider=(value)
      super(value&.slice(:vendor, :name, :id, :data))
    end

    def provider
      (super || {}).transform_keys(&:to_sym)
    end

    # @return [String]
    def provider_vendor
      self.provider[:vendor]
    end

    # @return [String]
    def provider_name
      self.provider[:name]
    end

    # @return [String]
    def provider_id
      self.provider[:id]
    end

    # @param [String] vendor
    # @param [String] name
    # @option [String, nil] id
    # @return [Boolean]
    def is_provided_by?(vendor:, name:, id: nil)
      vendor == self.provider_vendor && name == self.provider_name && (id.nil? || id == self.provider_id)
    end
  end
end
