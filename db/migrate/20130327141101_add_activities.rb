# -*- coding: utf-8 -*-
class AddActivities < ActiveRecord::Migration

  def change
    # Campaigns
    create_table :campaigns do |t|
      t.string :name, :null => false
      t.string :description
      t.string :nomen # code or nomenclature if XML
      t.boolean :closed, :null => false, :default => false # Flag pour dire si une campagne est clôturé ou non
      t.datetime :closed_at
      t.stamps
    end
    add_stamps_indexes :campaigns
    add_index :campaigns, :name

    # Activities
    create_table :activities do |t|
      t.string :name, :null => false
      t.string :description
      t.string :nomen                  # code or nomenclature if XML
      t.string :family, :null => false # classification (végétal, animal, mecanisation)
      t.string :nature, :null => false # main, auxiliary, undefined
      t.datetime :started_at
      t.datetime :stopped_at  # Defines when activity is closed
      t.references :parent    # Parent activity
      t.integer :lft
      t.integer :rgt
      t.integer :depth
      t.stamps
    end
    add_stamps_indexes :activities
    add_index :activities, :name
    add_index :activities, :parent_id

    # ActivityWatching
    create_table :activity_watchings do |t|
      t.references :activity, :null => false
      t.references :product_nature, :null => false
      t.references :work_unit # fr: unit d'œuvre
      t.references :area_unit # fr: unité de surface
      t.integer :position
      t.stamps
    end
    add_stamps_indexes :activity_watchings
    add_index :activity_watchings, :activity_id
    add_index :activity_watchings, :product_nature_id
    add_index :activity_watchings, :work_unit_id
    add_index :activity_watchings, :area_unit_id

    # ActivityRepartition
    create_table :activity_repartitions do |t|
      t.references :activity,              :null => false # lien avec une activité
      t.references :journal_entry_item,    :null => false # lien avec une ligne d'une écriture comptable
      t.string     :state,           :null => false       # locked, waiting, slave... etat (verouillé, en cours, en attente , esclave des opérations, maître des opérations)
      t.date       :affected_on,           :null => false # date de la repartition
      t.references :product_nature                      # lien avec un type de produit
      t.references :campaign                            # lien avec une campagne
      t.decimal    :percentage,    :null => false, :precision => 19, :scale => 4 # % de repartition de la ligne sur l'activité
      t.text       :description                           # description
      t.stamps
    end
    add_stamps_indexes :activity_repartitions
    add_index :activity_repartitions, :activity_id
    add_index :activity_repartitions, :journal_entry_item_id
    add_index :activity_repartitions, :product_nature_id
    add_index :activity_repartitions, :campaign_id

    # add a link between product_indicators and product_nature
    add_column :product_indicators, :product_nature_id, :integer
    add_index :product_indicators, :product_nature_id

  end

end
