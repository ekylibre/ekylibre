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
      res = ActiveRecord::Base.connection.execute <<~SQL
        SELECT ST_IsValid(ST_GeomFromEWKT('#{shape.to_ewkt}')) AS v
      SQL

      res.to_a.first['v'] == 't'
    end
end
