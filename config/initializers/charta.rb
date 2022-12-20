require 'charta'

module Charta
  class Geometry
    def buffer(radius)
      buffer_text = ActiveRecord::Base.connection.execute("SELECT ST_AsText(ST_Buffer(ST_GeomFromText('#{feature.as_text}')::geography, #{radius})) AS buffer").first['buffer']
      Charta.new_geometry(buffer_text)
    end
  end
end

class PostgresValidatedEwktFeatureBuilder
  # @return [Charta::Factory::EwktFeatureBuilder]
  attr_reader :decorated
  # @return [ShapeCorrector]
  attr_reader :shape_corrector

  def initialize(decorated:, shape_corrector:)
    @decorated = decorated
    @shape_corrector = shape_corrector
  end

  # @param [String] ewkt EWKT representation of a feature
  # @return [RGeo::Feature::Instance]
  def from_ewkt(ewkt)
    decorated.from_ewkt(ewkt)
  rescue RGeo::Error::InvalidGeometry => original
    shape_corrector.try_fix_ewkt(ewkt)
                   .fmap { |fixed| decorated.from_ewkt(fixed) }
                   .or_raise(original)
  end
end

if (ActiveRecord::Base.connection.present? rescue false)
  Charta.default_feature_factory = Charta::Factory::SimpleFeatureFactory.new(
    ewkt_builder: PostgresValidatedEwktFeatureBuilder.new(decorated: Charta::Factory::EwktFeatureBuilder.new, shape_corrector: ShapeCorrector.build),
    srid_provider: Charta::Factory::SridProvider.build,
    transformer: Charta::Factory::Transformers::EwktTransformerChain.build
  )
end