# -*- coding: utf-8 -*-
class AddActivities < ActiveRecord::Migration

  def change
    # Campaigns
    create_table :campaigns do |t|
      t.string   :name, :null => false
      t.string   :description
      t.boolean  :closed, :null => false, :default => false # Flag pour dire si une campagne est clôturé ou non
      t.datetime :closed_at
      t.stamps
    end
    add_stamps_indexes :campaigns
    add_index :campaigns, :name

    # Activities
    create_table :activities do |t|
      t.string :name, :null => false
      t.string :description
      t.string :family
      t.string :nature, :null => false # main, auxiliary, none
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

    # ActivityRepartition
    create_table :analytic_repartitions do |t|
      t.references :production,           :null => false # Link to activity
      t.references :journal_entry_item,   :null => false # lien avec une ligne d'une écriture comptable
      t.string     :state,                :null => false # locked, waiting, slave... etat (verrouillé, en cours, en attente, esclave des opérations, maître des opérations...)
      t.date       :affected_on,          :null => false # date de la repartition
      t.decimal    :affectation_percentage, :null => false, :precision => 19, :scale => 4 # % de repartition de la ligne sur l'activité
      # t.text       :description                # description
      t.stamps
    end
    add_stamps_indexes :analytic_repartitions
    add_index :analytic_repartitions, :production_id
    add_index :analytic_repartitions, :journal_entry_item_id
  end

end
