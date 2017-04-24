module AgroSystemes
  class SoilAnalysesExchanger < ActiveExchanger::Base
    SOIL_NATURES = {
      'LIMON SABLEUX' => :silt_soil,
      'ARGILO CALCAIRE MOYEN' => :clay_limestone_soil,
      'ARGILO CALCAIRE PROFOND' => :clay_limestone_soil,
      'ARGILO CALCAIRE SUPERFICIEL' => :clay_limestone_soil
    }.freeze

    def import
      here = Pathname.new(__FILE__).dirname

      analyser_attributes = YAML.load_file(here.join('entity.yml'))
      unless (analyser = Entity.find_by(siret_number: analyser_attributes[:siret_number]))
        analyser = Entity.create!(analyser_attributes)
      end

      begin
        rows = CSV.read(file, encoding: 'CP1252', col_sep: "\t", headers: true)
      rescue
        raise NotWellFormedFileError
      end
      w.count = rows.size

      rows.each do |row|
        r = OpenStruct.new(
          code_distri: (row[0].blank? ? nil : row[0].to_s),
          reference_number: row[6].to_s,
          at: (row[7].blank? ? nil : Date.civil(*row[7].to_s.split(/\//).reverse.map(&:to_i))),
          land_parcel_work_number: row[8].blank? ? nil : find_land_parcel(row[8]),
          analyse_soil_nature: row[10].blank? ? nil : SOIL_NATURES[row[10]],
          organic_matter_concentration: row[38].blank? ? nil : row[38].to_d.in_percent,
          potential_hydrogen: row[41].blank? ? nil : row[41].to_d,
          cation_exchange_capacity: row[47].blank? ? nil : row[47].to_d.in_milliequivalent_per_hundred_gram,
          p2o5_olsen_ppm_value: row[49].blank? ? nil : row[49].to_d.in_parts_per_million,
          p_ppm_value: row[49].blank? ? nil : (row[49].to_d * 0.436).in_parts_per_million,
          k2o_ppm_value: row[55].blank? ? nil : row[55].to_d.in_parts_per_million,
          k_ppm_value: row[55].blank? ? nil : (row[55].to_d * 0.83).in_parts_per_million,
          mg_ppm_value: row[61].blank? ? nil : row[61].to_d.in_parts_per_million,
          b_ppm_value: row[82].blank? ? nil : row[82].to_d.in_parts_per_million,
          zn_ppm_value: row[85].blank? ? nil : row[85].to_d.in_parts_per_million,
          mn_ppm_value: row[88].blank? ? nil : row[88].to_d.in_parts_per_million,
          cu_ppm_value: row[91].blank? ? nil : row[91].to_d.in_parts_per_million,
          fe_ppm_value: row[94].blank? ? nil : row[94].to_d.in_parts_per_million,
          sampled_at: (row[179].blank? ? nil : Date.civil(*row[179].to_s.split(/\//).reverse.map(&:to_i)))
        )

        analysis = Analysis.create_with(
          nature: 'soil_analysis',
          sampled_at: r.sampled_at,
          analysed_at: r.at
        ).find_or_create_by!(
          reference_number: r.reference_number,
          analyser: analyser
        )

        analysis.read!(:soil_nature, r.analyse_soil_nature) if r.analyse_soil_nature
        analysis.read!(:organic_matter_concentration, r.organic_matter_concentration) if r.organic_matter_concentration
        analysis.read!(:phosphorus_concentration, r.p_ppm_value) if r.p_ppm_value
        analysis.read!(:potassium_concentration, r.k_ppm_value) if r.k_ppm_value
        analysis.read!(:potential_hydrogen, r.potential_hydrogen) if r.potential_hydrogen
        analysis.read!(:cation_exchange_capacity, r.cation_exchange_capacity) if r.cation_exchange_capacity
        analysis.read!(:phosphate_concentration, r.p2o5_olsen_ppm_value) if r.p2o5_olsen_ppm_value
        analysis.read!(:potash_concentration, r.k2o_ppm_value) if r.k2o_ppm_value
        analysis.read!(:magnesium_concentration, r.mg_ppm_value) if r.mg_ppm_value
        analysis.read!(:boron_concentration, r.b_ppm_value) if r.b_ppm_value
        analysis.read!(:zinc_concentration, r.zn_ppm_value) if r.zn_ppm_value
        analysis.read!(:manganese_concentration, r.mn_ppm_value) if r.mn_ppm_value
        analysis.read!(:copper_concentration, r.cu_ppm_value) if r.cu_ppm_value
        analysis.read!(:iron_concentration, r.fe_ppm_value) if r.fe_ppm_value

        # if a land_parcel exist, link to analysis
        land_parcel = LandParcel.find_by(work_number: r.land_parcel_work_number)
        analysis.update(product: land_parcel) if land_parcel

        w.check_point
      end
    end

    # Search for cultivable_zone with its name
    def find_land_parcel(name)
      zones = LandParcel.where('TRIM(name) ILIKE ?', name.to_s.strip)
      unless zones.any?
        zones = LandParcel.where('TRIM(name) ILIKE ?', '%' + name.to_s.strip + '%')
        unless zones.any?
          zones = LandParcel.where('TRIM(name) ILIKE ?', '%' + name.to_s.strip.gsub(/\s+/, '%') + '%')
          unless zones.any?
            zones = LandParcel.where('TRIM(work_number) ILIKE ?', name.to_s.strip)
          end
        end
      end
      zones.first
    end
  end
end
