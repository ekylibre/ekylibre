# frozen_string_literal: true

class ShapeCorrector
  DEFAULT_CHANGE_PERCENTAGE_THRESHOLD = 0.01.freeze

  class << self
    def build
      new(
        connection: Ekylibre::Record::Base.connection,
        change_threshold: DEFAULT_CHANGE_PERCENTAGE_THRESHOLD
      )
    end
  end

  def initialize(connection:, change_threshold:)
    @connection = connection
    @change_threshold = change_threshold
  end

  # @param [Charta::Geometry] shape
  # @return [Maybe<Charta::Geometry>]
  def try_fix(shape)
    new_shape = try_fix_ewkt(shape.to_ewkt)
                  .fmap { |ewkt| Charta.new_geometry(ewkt) }
                  .or_else { return None() }

    area_ratio(shape, new_shape).fmap do |ratio|
      if (ratio - 1).abs < @change_threshold
        Some(new_shape)
      else
        None()
      end
    end
  end

  # @param [String] ewkt
  # @return [Maybe<String>]
  def try_fix_ewkt(ewkt)
    try_postgis_fix(ewkt)
  end

  private

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