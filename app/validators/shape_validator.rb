# frozen_string_literal: true

class ShapeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?

    record.errors.add(attribute, :empty_shape) if !options[:allow_empty] && value.empty?
    record.errors.add(attribute, :invalid_shape) if !valid?(value)
  end

  private

    # @param [Charta::Geometry] shape
    # @return [Boolean]
    def valid?(shape)
      pg_res = ActiveRecord::Base.connection.execute <<~SQL
        SELECT ST_IsValid(ST_GeomFromEWKT('#{shape.to_ewkt}')) AS v
      SQL

      # With AR 4.2 't' was returned
      # With AR 5.0, we have true
      res = pg_res.to_a.first['v']

      res.is_a?(TrueClass) || res == 't'
    end
end
