# frozen_string_literal: true

class CultivableZoneAnalysis
  def initialize(cultivable_zone)
    @cultivable_zone = cultivable_zone
  end

  def find_last_analysis(nature)
    if nature == :ndvi
      analysis_ids = Analysis.where(cultivable_zone_id: @cultivable_zone.id).with_indicator('minimal_ndvi_index')
    elsif nature == :soil
      analysis_ids = Analysis.where(cultivable_zone_id: @cultivable_zone.id).with_indicator('soil_moisture')
    end
    if analysis_ids.any?
      last_analysis = Analysis.where(id: analysis_ids).reorder(:analysed_at).last
      last_analysis.analysed_at
    else
      nil
    end
  end

end
