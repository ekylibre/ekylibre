# frozen_string_literal: true

class OpenWeatherMapClient
  DOMAIN = 'api.openweathermap.org'

  attr_accessor :apikey

  def self.from_identifier(identifier)
    new(Maybe(identifier).value)
  end

  def initialize(apikey)
    @apikey = apikey
  end

  def client
    @client ||= build_client
  end

  def fetch_forecast(coordinates)
    if apikey.is_none?
      logger.warn 'Missing OpenWeatherMap api key in identifiers)'
      return None()
    end

    begin
      return Maybe(client.get(url_for(*coordinates))).fmap { |res| JSON.parse(res.body).presence }
    rescue Net::OpenTimeout => e
      logger.warn "Net::OpenTimeout: Cannot open service OpenWeatherMap in time (#{e.message})"
    rescue Net::ReadTimeout => e
      logger.warn "Net::ReadTimeout: Cannot read service OpenWeatherMap in time (#{e.message})"
    rescue StandardError => e
      logger.warn "Unexpected error while requesting data from OpenWeatherMap (#{e.message})"
    end
    None()
  end

  private

    def logger
      Rails.logger
    end

    def url_for(lat, lng)
      "/data/2.5/forecast?lat=#{lat}&lon=#{lng}&mode=json&APPID=#{apikey.get}"
    end

    def build_client
      client = Net::HTTP.new('api.openweathermap.org')
      client.open_timeout = 3
      client.read_timeout = 3
      client
    end
end
