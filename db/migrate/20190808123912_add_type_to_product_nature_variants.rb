class AddTypeToProductNatureVariants < ActiveRecord::Migration
  def change
    add_column :product_nature_variants, :type, :string
    add_column :product_nature_variants, :imported_from, :string

    sub_natures_categories = { fertilizer: %w[fertilizer],
                               plant_medicine: %w[plant_medicine],
                               seed_and_plant: %w[seed plant] }

    sub_natures_account = { fertilizer: 'fertilizer_expenses',
                            plant_medicine: 'plant_medicine_matter_expenses',
                            seed_and_plant: 'seed_expenses' }

    sub_natures_varieties = { fertilizer: %w[compost guano liquid_slurry manure slurry],
                              seed_and_plant: %w[seed seedling] }

    execute <<-SQL
      UPDATE product_nature_variants
        SET imported_from = 'Nomenclature'
      WHERE reference_name IS NOT NULL;
    SQL

    request = sub_natures_categories.map do |nature, categories|
      categories_string = "'#{categories.join("', '")}'"
      <<-SQL.strip
        UPDATE product_nature_variants AS v
         SET type = 'Variants::Articles::#{nature.to_s.classify}Article'
        FROM product_nature_categories AS c
        WHERE v.category_id = c.id
          AND c.reference_name IN (#{categories_string});
      SQL
    end
    execute request.join

    request = sub_natures_account.map do |nature, account|
      <<-SQL.strip
        UPDATE product_nature_variants AS v
         SET type = 'Variants::Articles::#{nature.to_s.classify}Article'
        FROM product_nature_categories AS c
          INNER JOIN accounts AS a
          ON c.charge_account_id = a.id
            AND a.usages = '#{account}'
        WHERE v.category_id = c.id
          AND v.type IS NULL;
      SQL
    end
    execute request.join

    request = sub_natures_varieties.map do |nature, varieties|
      varieties_string = "'#{varieties.join("', '")}'"
      <<-SQL.strip
        UPDATE product_nature_variants AS v
         SET type = 'Variants::Articles::#{nature.to_s.classify}Article'
        FROM product_natures AS n
        WHERE v.nature_id = n.id
          AND n.variety IN (#{varieties_string})
          AND v.type IS NULL;
      SQL
    end
    execute request.join

    request = %w[Animal Article Crop Equipment Service Worker Zone].map do |nature|
      <<-SQL.strip
        UPDATE product_nature_variants AS v
          SET type = 'Variants::#{nature}Variant'
        FROM product_natures AS n
        WHERE v.nature_id = n.id
          AND n.type = 'VariantTypes::#{nature}Type'
          AND v.type IS NULL;
      SQL
    end
    execute request.join

    change_column_null :product_nature_variants, :type, false
  end
end
