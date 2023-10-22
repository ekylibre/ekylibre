# frozen_string_literal: true

class OpenWeatherMapClient
  DOMAIN = 'api.openweathermap.org'

  attr_accessor :apikey, :current_user

  def self.from_identifier(identifier, current_user)
    new(identifier&.value&.strip, current_user)
  end

  def initialize(apikey, current_user)
    @apikey = apikey
    lg = current_user&.language
    @language = (lg.present? ? lg[0..1] : 'en')
  end

  def client
    @client ||= build_client
  end

  def fetch_forecast(coordinates)
    if coordinates.nil?
      logger.warn 'Missing Coordinates'
      return { "cod" => "401", "message" => :openweathermap_missing_coordinates.tl }
    end

    if apikey.nil?
      logger.warn 'Missing OpenWeatherMap api key in identifiers'
      return { "cod" => "401", "message" => :openweathermap_missing_apikey.tl }
    end

    begin
      call = client.get(url_for(*coordinates))
      response = JSON.parse(call.body)
    rescue Net::OpenTimeout => e
      logger.warn "Net::OpenTimeout: Cannot open service OpenWeatherMap in time (#{e.message})"
      nil
    rescue Net::ReadTimeout => e
      logger.warn "Net::ReadTimeout: Cannot read service OpenWeatherMap in time (#{e.message})"
      nil
    rescue StandardError => e
      logger.warn "Unexpected error while requesting data from OpenWeatherMap (#{e.message})"
      nil
    end
  end

  private

    def logger
      Rails.logger
    end

    def url_for(lat, lng)
      "/data/2.5/forecast?lat=#{lat}&lon=#{lng}&units=metric&lang=#{@language}&appid=#{@apikey}"
    end

    def build_client
      client = Net::HTTP.new(DOMAIN)
      client.open_timeout = 3
      client.read_timeout = 3
      client
    end
end
