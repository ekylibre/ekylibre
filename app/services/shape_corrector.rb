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
  # @return [Maybe<Charta::Geometry>]
  def try_fix(shape)
    try_fix_ewkt(shape.to_ewkt)
      .fmap { |ewkt| Charta.new_geometry(ewkt) }
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
end
