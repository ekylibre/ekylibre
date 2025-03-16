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

  def create_agromonitoring_ndvi_analysis(items)
    items.each do |item|
      reference_number = item[:dt].to_s + '_ndvi'
      unless (analysis = Analysis.find_by(reference_number: reference_number))
        analysis = Analysis.create!(
          reference_number: reference_number,
          cultivable_zone_id: @cultivable_zone.id,
          nature: 'sensor_analysis',
          sampled_at: Time.at(item[:dt].to_i),
          analysed_at: Time.at(item[:dt].to_i)
        )
        analysis.read!(:minimal_ndvi_index, item[:data][:min].to_f) if item[:data][:min].present?
        analysis.read!(:maximal_ndvi_index, item[:data][:max].to_f) if item[:data][:max].present?
        analysis.read!(:average_ndvi_index, item[:data][:mean].to_f) if item[:data][:mean].present?
        analysis.read!(:median_ndvi_index, item[:data][:median].to_f) if item[:data][:median].present?
      end
    end
  end

  def create_agromonitoring_soil_analysis(item)
    reference_number = item[:dt].to_s + '_soil'
    unless (analysis = Analysis.find_by(reference_number: reference_number))
      analysis = Analysis.create!(
        reference_number: reference_number,
        cultivable_zone_id: @cultivable_zone.id,
        nature: 'sensor_analysis',
        sampled_at: Time.at(item[:dt].to_i),
        analysed_at: Time.at(item[:dt].to_i)
      )
      analysis.read!(:soil_moisture, item[:moisture].to_d.in_percent) if item[:moisture].present?
      analysis.read!(:soil_surface_temperature, (item[:t0].to_d - 273.15).in_celsius) if item[:t0].present?
      analysis.read!(:soil_10cm_depth_surface_temperature, (item[:t10].to_d - 273.15).in_celsius) if item[:t10].present?
    end
  end
end
