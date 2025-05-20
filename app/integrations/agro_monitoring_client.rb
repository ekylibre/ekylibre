# frozen_string_literal: true

class AgroMonitoringClient
  DOMAIN = 'http://api.agromonitoring.com/agro/1.0'
  VENDOR = 'agromonitoring'

  # test in console
  # API_KEY= '8e18ea1c1f9049d5bd91ecdd29754eeb'
  # agromonitoring_api_key = Identifier.find_by(nature: :agromonitoring_api_key)
  # current_user = User.first
  # cz = CultivableZone.last
  # weather_client = AgroMonitoringClient.from_identifier(agromonitoring_api_key, cz, current_user)

  attr_accessor :apikey, :current_user, :parcel

  def self.from_identifier(identifier, parcel, current_user = nil)
    new(identifier&.value&.strip, parcel, current_user)
  end

  def initialize(apikey, parcel, current_user = nil)
    @apikey = apikey
    lg = (current_user.present? ? current_user.language : User.first.language)
    @language = (lg.present? ? lg[0..1] : 'en')
    @parcel = parcel
  end

  def client
    @client = Faraday.new(
      url: DOMAIN,
      params: { appid: @apikey },
      headers: { 'Content-Type' => 'application/json' }
    ) do |f|
      f.request :json
      f.response :logger
      f.response :raise_error
      f.response :json
    end
  end

  def set_polygon
    if @parcel.shape.blank?
      logger.warn "No shape for parcel id:#{parcel.id}"
      return nil
    end

    if @parcel.is_provided_by?(vendor: VENDOR, name: 'agromonitoring_polygons')
      logger.warn "Parcel already present in Agromonitoring polygons"
      return nil
    end

    name = @parcel.name
    shape_json = RGeo::GeoJSON.encode(@parcel.shape.to_rgeo.first) # ::Charta.new_geometry(parcel.shape.to_rgeo.first).to_geojson #
    geo_json = { type: "Feature", properties: {}, geometry: shape_json }
    body = { name: name, geo_json: geo_json }
    begin
      # call API
      response = client.post('polygons', body)
    rescue Faraday::Error => e
      puts e.response[:status].inspect.red
      puts e.response[:body].inspect.yellow
      logger.warn "Faraday::Error (#{e.message})"
      nil
    end
    # update parcel provider
    @parcel.update!(
      provider: { vendor: VENDOR, name: 'agromonitoring_polygons', data: { id: response.body["id"].to_s } }
    )
  end

  def remove_polygon
    unless @parcel.is_provided_by?(vendor: VENDOR, name: 'agromonitoring_polygons')
      logger.warn "Parcel NOT already present in Agromonitoring polygons. Use set_polygon method first"
      return nil
    end
    begin
      # call API
      response = client.delete("polygons/#{@parcel.provider[:data]['id']}")
    rescue Faraday::Error => e
      puts e.response[:status].inspect.red
      puts e.response[:body].inspect.yellow
      logger.warn "Faraday::Error (#{e.message})"
      nil
    end
  end

  def grab_ndvi_history(stopped_at = Time.now, clouds_max = 10)
    if @parcel.shape.blank?
      logger.warn "No shape for parcel id:#{parcel.id}"
      return nil
    end
    @parcel.reload
    unless @parcel.is_provided_by?(vendor: VENDOR, name: 'agromonitoring_polygons')
      logger.warn "Parcel NOT already present in Agromonitoring polygons.Use set_polygon method first"
      return nil
    end

    begin
      # call API
      response = client.get('ndvi/history') do |req|
        req.params['polygon_id'] = @parcel.provider[:data]['id']
        req.params['start'] = ( stopped_at - 4.year ).to_i
        req.params['end'] = stopped_at.to_i
        req.params['clouds_max'] = clouds_max
      end
    rescue Faraday::Error => e
      puts e.response[:status].inspect.red
      puts e.response[:body].inspect.yellow
      logger.warn "Faraday::Error (#{e.message})"
      nil
    end
    # return to store data in analysis for cultivable zone
    response.body.map(&:deep_symbolize_keys)
  end

  def grab_current_soil
    if @parcel.shape.blank?
      logger.warn "No shape for parcel id:#{parcel.id}"
      return nil
    end
    @parcel.reload
    unless @parcel.is_provided_by?(vendor: VENDOR, name: 'agromonitoring_polygons')
      logger.warn "Parcel NOT already present in Agromonitoring polygons.Use set_polygon method first"
      return nil
    end

    begin
      # call API
      response = client.get('soil') do |req|
        req.params['polyid'] = @parcel.provider[:data]['id']
      end
    rescue Faraday::Error => e
      puts e.response[:status].inspect.red
      puts e.response[:body].inspect.yellow
      logger.warn "Faraday::Error (#{e.message})"
      nil
    end
    # return to store data in analysis for cultivable zone
    response.body.deep_symbolize_keys
  end

  private

    def logger
      Rails.logger
    end

end
