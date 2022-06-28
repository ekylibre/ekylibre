require 'elasticsearch'
module Ekylibre
  class ElasticClient
    # ELASTIC_URL = ENV['ELASTIC_URL']
    ELASTIC_HOST = ENV['ELASTIC_HOST']
    # ELASTIC_API_ID = ENV['ELASTIC_API_ID']
    # ELASTIC_API_KEY = ENV['ELASTIC_API_KEY']
    CERT_FINGERPRINT = ENV['ELASTIC_SHA_FINGERPRINT']

    def initialize
      @client = Elasticsearch::Client.new(
        host: ELASTIC_HOST,
        transport_options: { ssl: { verify: false } },
        ca_fingerprint: CERT_FINGERPRINT
      )
    end

    def create_or_update_mapping(table: nil, fields: {})
      return nil if table.nil? || fields.blank?

      body = {
         mappings: {
          dynamic: false,
          properties: fields
        }
      }
      if @client.indices.exists index: table
        @client.indices.put_mapping index: table, body: { properties: fields }
      else
        @client.indices.create index: table, body: body
      end
    end

    def bulk(data:)
      @client.bulk(body: data)
    end
  end
end
