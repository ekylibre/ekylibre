# frozen_string_literal: true

module Phytosanitary
  module Register
    module Exporters
      class Base
        SCHEMA_URN = 'urn:fr:agri:phyto:register:1.0'
        FORMAT_VERSION = '1.0'

        def self.call(payload)
          new(payload).call
        end

        def initialize(payload)
          @payload = payload
        end

        protected

          def serialize_value(value)
            case value
            when nil then nil
            when BigDecimal then value.to_s('F')
            when Date then value.iso8601
            when Time, DateTime, ActiveSupport::TimeWithZone then value.utc.iso8601
            when true, false then value
            else
              return value.as_text if value.respond_to?(:as_text)

              value
            end
          end

          def entry_hash(entry)
            entry.members.each_with_object({}) do |key, h|
              h[key] = serialize_value(entry[key])
            end
          end

          def meta_hash
            {
              schema: SCHEMA_URN,
              format_version: FORMAT_VERSION,
              holder_siret: @payload.holder_siret,
              holder_name: @payload.holder_name,
              campaign_name: @payload.campaign_name,
              period_from: serialize_value(@payload.period_from),
              period_to: serialize_value(@payload.period_to),
              generated_at: serialize_value(@payload.generated_at),
              entry_count: @payload.size
            }
          end
      end
    end
  end
end
