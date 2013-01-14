class ChangeProductAnimals < ActiveRecord::Migration
  def up

    rename_table :products, :product_natures
    rename_table :product_categories, :product_nature_categories
    rename_table :animals, :products
    rename_table :animal_groups, :product_groups
    rename_table :animal_races, :product_species
    rename_table :events, :entity_events
    rename_table :animal_events, :product_events
    rename_table :event_natures, :entity_event_natures
    rename_table :animal_event_natures, :product_event_natures
    rename_table :animal_group_events, :product_group_events

    change_table :products do |t|
      t.rename :race_id, :specy_id
      t.decimal :quantity
      t.integer :unit_id
      t.geometry :shape
    end

    change_table :product_events do |t|
      t.rename :animal_id, :product_id
      t.remove :planned_at
      t.remove :moved_at
    end

    change_table :product_group_events do |t|
      t.rename :animal_group_id, :product_group_id
      t.remove :planned_at
      t.remove :moved_at
    end

    create_table :product_group_passings do |t|
      t.belongs_to :product
      t.belongs_to :group
      t.datetime :entered_at
      t.datetime :departed_at
      t.stamps
    end
    add_stamps_indexes :product_group_passings
    add_index :product_group_passings, :product_id
    add_index :product_group_passings, :group_id

    create_table :product_group_natures do |t|
      t.string :name
      t.string :comment
      t.stamps
    end
    add_stamps_indexes :product_group_natures

    create_table :product_place_passings do |t|
      t.belongs_to :product
      t.belongs_to :place # c le nom de l'attribut qui stocke le produit qui fait office de warehouse
      t.datetime :entered_at
      t.datetime :departed_at
      t.stamps
    end
    add_stamps_indexes :product_place_passings
    add_index :product_place_passings, :product_id
    add_index :product_place_passings, :place_id

    drop_table :animal_diagnostics
    drop_table :animal_diseases
    drop_table :animal_drug_natures
    drop_table :animal_drugs
    drop_table :animal_posologies
    drop_table :animal_treatments
    drop_table :animal_prescriptions

  end

  def down

    change_table :product_group_events do |t|
      t.rename :product_group_id, :animal_group_id
      t.datetime :planned_at
      t.datetime :moved_at
    end

    change_table :product_events do |t|
      t.rename :product_id, :animal_id
      t.datetime :planned_at
      t.datetime :moved_at
    end

    change_table :products do |t|
      t.rename :specy_id, :race_id
      t.remove :quantity
      t.remove :unit_id
      t.remove :shape
    end

    rename_table :product_event_natures, :animal_event_natures
    rename_table :product_group_events, :animal_group_events
    rename_table :entity_event_natures, :event_natures
    rename_table :product_events, :animal_events
    rename_table :entity_events, :events
    rename_table :product_species, :animal_races
    rename_table :product_groups, :animal_groups
    rename_table :products, :animals
    rename_table :product_nature_categories, :product_categories
    rename_table :product_natures, :products

    drop_table :product_group_passings
    drop_table :product_group_natures
    drop_table :product_place_passings


  end

end
