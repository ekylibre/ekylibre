# frozen_string_literal: true

module CviCultivableZoneService
  class ShapeCalculator
    def self.calculate(cvi_cultivable_zone, shape)
      if cvi_cultivable_zone.has_cvi_land_parcels?
        CviLandParcel.select("st_astext(
                                ST_Simplify(
                                  ST_UNION(
                                    ARRAY_AGG(
                                      array[
                                        ST_MakeValid(cvi_land_parcels.shape),
                                        ST_MakeValid(
                                          ST_GeomFromText(\'#{shape.as_text}\')
                                        )
                                      ]
                                    )
                                  ), 0.000000001
                                )
                              ) AS shape")
                        .joins(:cvi_cultivable_zone)
                        .find_by(cvi_cultivable_zone_id: cvi_cultivable_zone.id)
                        .shape.to_rgeo
      else
        shape
      end
    end
  end
end
