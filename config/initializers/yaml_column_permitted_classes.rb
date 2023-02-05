Rails.application.config.active_record.yaml_column_permitted_classes =
  [
    ActiveSupport::HashWithIndifferentAccess,
    ActiveSupport::TimeWithZone,
    ActiveSupport::TimeZone,
    ActiveSupport::TimeZone,
    BigDecimal,
    Charta::MultiPolygon,
    Charta::Point,
    Measure,
    Rational,
    RGeo::Geographic::ProjectedMultiPolygonImpl,
    RGeo::Geographic::ProjectedPointImpl,
    RGeo::Geographic::Factory,
    Time,
    Date
  ]

if defined?(RGeo::Geos::CAPIFactory)
  Rails.application.config.active_record.yaml_column_permitted_classes << RGeo::Geos::CAPIFactory
end
if defined?(RGeo::Geos::CAPIMultiPolygonImpl)
  Rails.application.config.active_record.yaml_column_permitted_classes << RGeo::Geos::CAPIMultiPolygonImpl
end
if defined?(RGeo::Geos::CAPIPointImpl)
  Rails.application.config.active_record.yaml_column_permitted_classes << RGeo::Geos::CAPIPointImpl
end
