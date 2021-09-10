class CreateUnits < ActiveRecord::Migration
  UNITS = [["Million", "million", 37, "M.", 1000000.0, "none", "ReferenceUnit"],
           ["Acre", "acre", 33, "acre", 4046.8564224, "surface_area", "ReferenceUnit"],
           ["Are", "are", 33, "a", 100.0, "surface_area", "ReferenceUnit"],
           ["Milliard", "billion", 37, "G.", 1000000000.0, "none", "ReferenceUnit"],
           ["Milliardième", "billionth", 37, "n.", 1.0e-09, "none", "ReferenceUnit"],
           ["Centilitre", "centiliter", 21, "cl", 0.01, "volume", "ReferenceUnit"],
           ["Centimètre", "centimeter", 22, "cm", 0.01, "distance", "ReferenceUnit"],
           ["Centimètre cube", "cubic_centimeter", 21, "cm³", 0.001, "volume", "ReferenceUnit"],
           ["Mètre cube", "cubic_meter", 21, "m³", 1000.0, "volume", "ReferenceUnit"],
           ["Jour", "day", 31, "d", 86400.0, "time", "ReferenceUnit"],
           ["Douzaine", "dozen", 37, "dz", 12.0, "none", "ReferenceUnit"],
           ["Gramme", "gram", 18, "g", 0.001, "mass", "ReferenceUnit"],
           ["Hectare", "hectare", 33, "ha", 10000.0, "surface_area", "ReferenceUnit"],
           ["Hectolitre", "hectoliter", 21, "hl", 100.0, "volume", "ReferenceUnit"],
           ["Heure", "hour", 31, "h", 3600.0, "time", "ReferenceUnit"],
           ["Centaine", "hundred", 37, "h.", 100.0, "none", "ReferenceUnit"],
           ["Joule", "joule", 17, "J", 1.0, "energy", "ReferenceUnit"],
           ["Kilogramme", "kilogram", 18, "kg", 1.0, "mass", "ReferenceUnit"],
           ["Kilomètre", "kilometer", 22, "km", 1000.0, "distance", "ReferenceUnit"],
           ["Kilowatt-heure", "kilowatt_hour", 17, "kWh", 3600000.0, "energy", "ReferenceUnit"],
           ["Litre", "liter", 21, "l", 1.0, "volume", "ReferenceUnit"],
           ["Mètre", "meter", 22, "m", 1.0, "distance", "ReferenceUnit"],
           ["Microgramme", "microgram", 18, "µg", 1.0e-09, "mass", "ReferenceUnit"],
           ["Milligramme", "milligram", 18, "mg", 1.0e-06, "mass", "ReferenceUnit"],
           ["Millilitre", "milliliter", 21, "ml", 0.001, "volume", "ReferenceUnit"],
           ["Millimètre", "millimeter", 22, "mm", 0.001, "distance", "ReferenceUnit"],
           ["Millionième", "millionth", 37, "µ.", 1.0e-06, "none", "ReferenceUnit"],
           ["Milliseconde", "millisecond", 31, "ms", 0.001, "time", "ReferenceUnit"],
           ["Minute", "minute", 31, "min", 60.0, "time", "ReferenceUnit"],
           ["Quintal", "quintal", 18, "q", 100.0, "mass", "ReferenceUnit"],
           ["Seconde", "second", 31, "s", 1.0, "time", "ReferenceUnit"],
           ["Centimètre carré", "square_centimeter", 33, "cm²", 0.0001, "surface_area", "ReferenceUnit"],
           ["Mètre carré", "square_meter", 33, "m²", 1.0, "surface_area", "ReferenceUnit"],
           ["Millier", "thousand", 37, "k.", 1000.0, "none", "ReferenceUnit"],
           ["Millième", "thousandth", 37, "m.", 0.001, "none", "ReferenceUnit"],
           ["Tonne", "ton", 18, "t", 1000.0, "mass", "ReferenceUnit"],
           ["Unité", "unity", 37, ".", 1.0, "none", "ReferenceUnit"],
           ["Big bag de 1000 kg", "1000kg_big_bag", 18, nil, 1000.0, "mass", "Conditioning"],
           ["Bidon de 10 L", "10l_can", 21, nil, 10.0, "volume", "Conditioning"],
           ["Sac de 125000 grains", "125tg_bag", 34, nil, 125.0, "none", "Conditioning"],
           ["Sac de 12 kg", "12kg_bag", 18, nil, 12.0, "mass", "Conditioning"],
           ["Bouteille de 13 kg", "13kg_bottle", 18, nil, 13.0, "mass", "Conditioning"],
           ["Sac de 150000 grains", "150tg_bag", 34, nil, 150.0, "none", "Conditioning"],
           ["Bouteille de 1 L", "1l_bottle", 21, nil, 1.0, "volume", "Conditioning"],
           ["Bidon de 1 L", "1l_can", 21, nil, 1.0, "volume", "Conditioning"],
           ["Sac de 20 kg", "20kg_bag", 18, nil, 20.0, "mass", "Conditioning"],
           ["Sac de 25 kg", "25kg_bag", 18, nil, 25.0, "mass", "Conditioning"],
           ["Pot de 300 mL", "300ml_jar", 21, nil, 0.3, "volume", "Conditioning"],
           ["Big bag de 500 kg", "500kg_big_bag", 18, nil, 500.0, "mass", "Conditioning"],
           ["Sac de 50000 grains", "50tg_bag", 34, nil, 50.0, "none", "Conditioning"],
           ["Bidon de 5 L", "5l_can", 21, nil, 5.0, "volume", "Conditioning"],
           ["Big bag de 600 kg", "600kg_big_bag", 18, nil, 600.0, "mass", "Conditioning"],
           ["Bouteille de 75 cL", "75cl_bottle", 21, nil, 0.75, "volume", "Conditioning"],
           ["Balthazar", "balthazar", 21, nil, 12.0, "volume", "Conditioning"],
           ["Balle cubique 120x130x260", "cubic_bale_120_130_260", 9, nil, 4.06, "volume", "Conditioning"],
           ["Balle cubique 70x120x260", "cubic_bale_70_120_260", 9, nil, 2.18, "volume", "Conditioning"],
           ["Balle cubique 80x80x260", "cubic_bale_80_80_260", 9, nil, 1.66, "volume", "Conditioning"],
           ["Balle cubique 90x120x260", "cubic_bale_90_120_260", 9, nil, 2.81, "volume", "Conditioning"],
           ["Vrac (m3)", "cubic_meter_bulk", 9, nil, 1.0, "volume", "Conditioning"],
           ["Demi-bouteille", "half_bottle", 21, nil, 0.375, "volume", "Conditioning"],
           ["Heure d'utilisation d'équipement", "hour_equipment", 15, nil, 1.0, "time", "Conditioning"],
           ["Jéroboam", "jeroboam", 21, nil, 3.0, "volume", "Conditioning"],
           ["Vrac (kg)", "kilo_bulk", 18, nil, 1.0, "mass", "Conditioning"],
           ["Vrac (L)", "liter_bulk", 21, nil, 1.0, "volume", "Conditioning"],
           ["Magnum", "magnum", 21, nil, 1.5, "volume", "Conditioning"],
           ["Mathusalem", "mathusalem", 21, nil, 6.0, "volume", "Conditioning"],
           ["Nabuchodonosor", "nabuchodonosor", 21, nil, 15.0, "volume", "Conditioning"],
           ["Vrac (q)", "quintal_bulk", 30, nil, 1.0, "mass", "Conditioning"],
           ["Réhoboam", "rehoboam", 21, nil, 4.5, "volume", "Conditioning"],
           ["Balle ronde 120x120", "round_bale_120_120", 9, nil, 1.36, "volume", "Conditioning"],
           ["Balle ronde 120x160", "round_bale_120_160", 9, nil, 2.41, "volume", "Conditioning"],
           ["Balle ronde 120x180", "round_bale_120_180", 9, nil, 3.05, "volume", "Conditioning"],
           ["Salmanazar", "salmanazar", 21, nil, 9.0, "volume", "Conditioning"],
           ["Vrac (t)", "ton_bulk", 36, nil, 1.0, "mass", "Conditioning"],
           ["Vrac (unité)", "unity_bulk", 37, nil, 1.0, "none", "Conditioning"],
           ["Bag in box 2L", "2l_bib", 21, nil, 2.0, "volume", "Conditioning"],
           ["Bag in box 3L", "3l_bib", 21, nil, 3.0, "volume", "Conditioning"],
           ["Bag in box 5L", "5l_bib", 21, nil, 5.0, "volume", "Conditioning"],
           ["Bag in box 10L", "10l_bib", 21, nil, 10.0, "volume", "Conditioning"],
           ["Bag in box 15L", "15l_bib", 21, nil, 15.0, "volume", "Conditioning"],
           ["Bag in box 20L", "20l_bib", 21, nil, 20.0, "volume", "Conditioning"],
           ["Hectare travaillé", "worked_hectare", 13, nil, 1.0, "surface_area", "Conditioning"]]

  def up
    create_table :units do |t|
      t.string      :name, null: false
      t.string      :reference_name
      t.references  :base_unit, index: true
      t.string      :symbol
      t.string      :work_code
      t.decimal     :coefficient, precision: 20, scale: 10, default: 1.0, null: false
      t.text        :description
      t.string      :dimension, null: false
      t.string      :type, null: false
      t.timestamps
    end


    sql_units = UNITS.map do |name, reference_name, base_unit_id, symbol, coefficient, dimension, type|
                    <<-VALUE.strip
                      (#{quote(name)}, #{quote(reference_name)}, #{quote(base_unit_id)}, #{quote(symbol)}, #{quote(coefficient)}, #{quote(dimension)}, #{quote(type)}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    VALUE
                  end
    execute <<-SQL
      INSERT INTO units (name, reference_name, base_unit_id, symbol, coefficient, dimension, type, created_at, updated_at)
        VALUES
          #{sql_units.join(',')}
    SQL
  end

  def down
    # NOOP
  end

  private

    def quote(value)
      ActiveRecord::Base.connection.quote value
    end
end
