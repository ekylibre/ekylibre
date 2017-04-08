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
  }.freeze

  WAYS = [
    %i[birth product born],
    %i[production product produced],
    # [:production, :producer, :producer],
    %i[division product separated],
    %i[division producer reduced],
    %i[death product dead],
    # [:consumption, :consumer, :consumer],
    %i[consumption product consumed],
    # [:merging, :absorber, :absorber],
    %i[merging product absorbed],
    %i[mixing product produced],
    %i[mixing first_producer mixed],
    %i[mixing second_producer mixed],
    %i[mixing third_producer mixed],
    %i[mixing fourth_producer mixed],
    %i[mixing fifth_producer mixed]
  ].freeze

  POLYMORPHIC_REFERENCES = [
    %i[attachments resource],
    %i[issues target],
    %i[journal_entries resource],
    %i[observations subject],
    %i[preferences record_value],
    %i[product_enjoyments originator],
    %i[product_junctions originator],
    %i[product_linkages originator],
    %i[product_links originator],
    %i[product_localizations originator],
    %i[product_memberships originator],
    %i[product_ownerships originator],
    %i[product_phases originator],
    %i[product_reading_tasks originator],
    %i[product_readings originator],
    %i[versions item]
  ].freeze

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
          execute "UPDATE #{table} SET #{reference}_type = 'ProductJunction' WHERE #{reference}_type IN (" + NATURES.keys.map { |n| "'#{n}'" }.join(', ') + ')'
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
