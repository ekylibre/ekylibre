# frozen_string_literal: true

class ShapeCorrector
  DEFAULT_CHANGE_PERCENTAGE_THRESHOLD = 0.01

  class << self
    def build
      new(
        connection: ApplicationRecord.connection,
        change_threshold: DEFAULT_CHANGE_PERCENTAGE_THRESHOLD
      )
    end
  end

  def initialize(connection:, change_threshold:)
    @connection = connection
    @change_threshold = change_threshold
  end

  # @param [Charta::Geometry] shape
  # @param [Hash] opts options
  # @option opts [Symbol] :geometry_type type of expected geometry
  # @return [Maybe<Charta::Geometry>]
  def try_fix(shape, geometry_type: nil)
    try_fix_ewkt(shape.to_ewkt)
      .fmap { |ewkt| Charta.new_geometry(ewkt) }
  rescue => e
    if geometry_type.present?
      try_complex_fix_ewkt(shape.to_ewkt, geometry_type: geometry_type)
        .fmap { |ewkt| Charta.new_geometry(ewkt) }
    else
      raise
    end
  end

  # @param [String] ewkt
  # @return [Maybe<String>]
  def try_fix_ewkt(ewkt)
    try_postgis_fix(ewkt)
  end

  # @param [String] ewkt
  # @param [Hash] opts options
  # @option opts [Symbol] :geometry_type type of expected geometry
  # @return [Maybe<String>]
  def try_complex_fix_ewkt(ewkt, geometry_type:)
    try_complex_postgis_fix(ewkt, geometry_type: geometry_type)
  end

  # @param [String] geojson
  # @param [String] srid
  # @return [Maybe<String>]
  def try_fix_geojson(geojson, srid)
    try_postgis_geojson_fix(geojson, srid)
  end

  # @param [String] ewkt
  # @param [Symbol] geometry_type
  # @return [Maybe<String>]
  def extract_geometries(ewkt, geometry_type)
    postgis_geometries_extraction(ewkt, geometry_type)
      .fmap { |ewkt| Charta.new_geometry(ewkt) }
  end

  private

    def postgis_geometries_extraction(ewkt, geometry_type)
      res = @connection.execute(<<~SQL).to_a.first
        SELECT
          ST_AsEWKT(
            ST_collectionExtract(
              ST_GeomFromEWKT('#{ewkt}')
            , #{find_postgis_integer_type(geometry_type)})
          )AS extracted_shape
      SQL

      if res.present?
        Maybe(res['extracted_shape'])
      else
        None()
      end
    end

    # @param [String] ewkt
    # @return [Maybe<String>]
    def try_postgis_fix(ewkt)
      res = @connection.execute(<<~SQL).to_a.first
        SELECT ST_AsEWKT(ST_MakeValid(ST_GeomFromEWKT('#{ewkt}'))) AS valid_shape
      SQL

      if res.present?
        Maybe(res['valid_shape'])
      else
        None()
      end
    end

    # @param [String] ewkt
    # @param [Hash] opts options
    # @option opts [Symbol] :geometry_type type of expected geometry
    # @return [Maybe<String>]
    def try_complex_postgis_fix(ewkt, geometry_type: nil)
      return None() if geometry_type.nil?

      res = @connection.execute(<<~SQL).to_a.first
        SELECT
          ST_AsEWKT(
            ST_MakeValid(
              ST_AsEWKT(
                ST_MakeValid(
                    ST_GeomFromEWKT('#{ewkt}')
                )
              )
            )
          ) AS valid_shape
      SQL

      if res.present?
        Maybe(res['valid_shape'])
      else
        None()
      end
    end

    def find_postgis_integer_type(type)
      return if type.nil?

      if type.to_s.include?('polygon')
        3
      elsif type.to_s.include?('line')
        2
      elsif type.to_s.include?('point')
        1
      end
    end

    # @param [String] geojson
    # @return [Maybe<String>]
    def try_postgis_geojson_fix(geojson, srid)
      res = @connection.execute(<<~SQL).to_a.first
        SELECT ST_AsEWKT(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON('#{geojson}'), #{srid}))) AS valid_shape
      SQL

      if res.present?
        Maybe(res['valid_shape'])
      else
        None()
      end
    end

    # @param [Charta::Geometry] original_shape
    # @param [Charta::Geometry] new_shape
    # @return [Maybe<Number>]
    def area_ratio(original_shape, new_shape)
      original_area = original_shape.area
      new_area = new_shape.area

      if original_area.positive?
        Some(new_area / original_area)
      else
        None()
      end
    end
end
