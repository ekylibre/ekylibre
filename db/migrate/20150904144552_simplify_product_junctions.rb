class SimplifyProductJunctions < ActiveRecord::Migration
  NATURES = {
    'ProductBirth' => :birth,
    'ProductConsumption' => :consumption,
    'ProductCreation' => :production,
    'ProductDeath' => :death,
    'ProductDivision' => :division,
    'ProductMerging' => :merging,
    'ProductMixing' => :mixing,
    'ProductQuadrupleMixing' => :mixing,
    'ProductQuintupleMixing' => :mixing,
    'ProductTripleMixing' => :mixing
  }

  WAYS = [
    [:birth, :product, :born],
    [:production, :product, :produced],
    # [:production, :producer, :producer],
    [:division, :product, :separated],
    [:division, :producer, :reduced],
    [:death, :product, :dead],
    # [:consumption, :consumer, :consumer],
    [:consumption, :product, :consumed],
    # [:merging, :absorber, :absorber],
    [:merging, :product, :absorbed],
    [:mixing, :product, :produced],
    [:mixing, :first_producer, :mixed],
    [:mixing, :second_producer, :mixed],
    [:mixing, :third_producer, :mixed],
    [:mixing, :fourth_producer, :mixed],
    [:mixing, :fifth_producer, :mixed]
  ]

  POLYMORPHIC_REFERENCES = [
    [:attachments, :resource],
    [:issues, :target],
    [:journal_entries, :resource],
    [:observations, :subject],
    [:preferences, :record_value],
    [:product_enjoyments, :originator],
    [:product_junctions, :originator],
    [:product_linkages, :originator],
    [:product_links, :originator],
    [:product_localizations, :originator],
    [:product_memberships, :originator],
    [:product_ownerships, :originator],
    [:product_phases, :originator],
    [:product_reading_tasks, :originator],
    [:product_readings, :originator],
    [:versions, :item]
  ]

  def change
    rename_column :product_junction_ways, :road_id, :product_id
    rename_column :product_junctions, :type, :nature
    reversible do |dir|
      dir.up do
        execute 'UPDATE product_junctions SET nature = CASE ' + NATURES.map { |class_name, nature| "WHEN nature = '#{class_name}' THEN '#{nature}'" }.join + " ELSE 'junction' END"
        WAYS.each do |jn, on, nn|
          execute "UPDATE product_junction_ways SET role = '#{nn}' FROM product_junctions AS pj WHERE pj.id = junction_id AND pj.nature = '#{jn}' AND product_junction_ways.role = '#{on}'"
        end
        POLYMORPHIC_REFERENCES.each do |table, reference|
          execute "UPDATE #{table} SET #{reference}_type = 'ProductJunction' WHERE #{reference}_type IN (" + NATURES.keys.map{ |n| "'#{n}'" }.join(', ') + ")"
        end
      end
      dir.down do
        WAYS.each do |jn, nn, on|
          execute "UPDATE product_junction_ways SET role = '#{nn}' FROM product_junctions AS pj WHERE pj.id = junction_id AND pj.nature = '#{jn}' AND product_junction_ways.role = '#{on}'"
        end
        execute 'UPDATE product_junctions SET nature = CASE ' + NATURES.map { |class_name, nature| "WHEN nature = '#{nature}' THEN '#{class_name}'" }.join + " ELSE 'junction' END"
      end
    end
    change_column_null :product_junctions, :nature, false
    revert do
      add_column :product_junction_ways, :population, :decimal, precision: 19, scale: 4
      add_column :product_junction_ways, :shape, :geometry, srid: 4326
    end
  end
end
