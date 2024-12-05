# frozen_string_literal: true

module Ekylibre
  class SoilAnalysesExchanger < ActiveExchanger::Base
    category :plant_farming
    vendor :ekylibre

    SOIL_NATURES = {
      'LIMON SABLEUX' => :silt_soil,
      'ARGILO CALCAIRE MOYEN' => :clay_limestone_soil,
      'ARGILO CALCAIRE PROFOND' => :clay_limestone_soil,
      'ARGILO CALCAIRE SUPERFICIEL' => :clay_limestone_soil
    }.freeze

    def import
      here = Pathname.new(__FILE__).dirname

      begin
        rows = CSV.read(file, encoding: 'UTF-8', col_sep: ",", headers: true)
      rescue
        raise NotWellFormedFileError
      end
      w.count = rows.size

      rows.each do |row|
        r = OpenStruct.new(
          reference_number: row[1].to_s,
          at: (row[0].blank? ? nil : Date.parse(row[0].to_s).to_time),
          land_parcel_work_number: (row[2].blank? ? nil : row[2].to_s),
          analyse_soil_nature: row[4].blank? ? nil : SOIL_NATURES[row[4].to_s],
          organic_matter_concentration: row[5].blank? ? nil : row[5].to_d.in_percent,
          potential_hydrogen: row[6].blank? ? nil : row[6].to_d,
          cation_exchange_capacity: row[7].blank? ? nil : row[7].to_d.in_milliequivalent_per_hundred_gram,
          p2o5_olsen_ppm_value: row[8].blank? ? nil : row[8].to_d.in_parts_per_million,
          # p_ppm_value: row[49].blank? ? nil : (row[49].to_d * 0.436).in_parts_per_million,
          k2o_ppm_value: row[9].blank? ? nil : row[9].to_d.in_parts_per_million,
          # k_ppm_value: row[55].blank? ? nil : (row[55].to_d * 0.83).in_parts_per_million,
          mg_ppm_value: row[11].blank? ? nil : row[11].to_d.in_parts_per_million,
          # b_ppm_value: row[82].blank? ? nil : row[82].to_d.in_parts_per_million,
          zn_ppm_value: row[14].blank? ? nil : row[14].to_d.in_parts_per_million,
          mn_ppm_value: row[15].blank? ? nil : row[15].to_d.in_parts_per_million,
          cu_ppm_value: row[16].blank? ? nil : row[16].to_d.in_parts_per_million,
          fe_ppm_value: row[17].blank? ? nil : row[17].to_d.in_parts_per_million
        )

        analysis = Analysis.create_with(
          nature: 'soil_analysis',
          sampled_at: r.at,
          analysed_at: r.at
        ).find_or_create_by!(
          reference_number: r.reference_number,
          analyser: Entity.of_company
        )

        analysis.read!(:soil_nature, r.analyse_soil_nature) if r.analyse_soil_nature
        analysis.read!(:organic_matter_concentration, r.organic_matter_concentration) if r.organic_matter_concentration
        # analysis.read!(:phosphorus_concentration, r.p_ppm_value) if r.p_ppm_value
        # analysis.read!(:potassium_concentration, r.k_ppm_value) if r.k_ppm_value
        analysis.read!(:potential_hydrogen, r.potential_hydrogen) if r.potential_hydrogen
        analysis.read!(:cation_exchange_capacity, r.cation_exchange_capacity) if r.cation_exchange_capacity
        analysis.read!(:phosphate_concentration, r.p2o5_olsen_ppm_value) if r.p2o5_olsen_ppm_value
        analysis.read!(:potash_concentration, r.k2o_ppm_value) if r.k2o_ppm_value
        analysis.read!(:magnesium_concentration, r.mg_ppm_value) if r.mg_ppm_value
        # analysis.read!(:boron_concentration, r.b_ppm_value) if r.b_ppm_value
        analysis.read!(:zinc_concentration, r.zn_ppm_value) if r.zn_ppm_value
        analysis.read!(:manganese_concentration, r.mn_ppm_value) if r.mn_ppm_value
        analysis.read!(:copper_concentration, r.cu_ppm_value) if r.cu_ppm_value
        analysis.read!(:iron_concentration, r.fe_ppm_value) if r.fe_ppm_value

        # if a land_parcel exist, link to analysis and set centroid of analysis
        cz = CultivableZone.find_by(work_number: r.land_parcel_work_number)
        if cz&.shape.present?
          lat = cz.shape_centroid[0]
          lon = cz.shape_centroid[1]
          analysis.update(cultivable_zone: cz, geolocation: ::Charta.new_point(lat, lon))
        end

        w.check_point
      end
    end

  end
end
