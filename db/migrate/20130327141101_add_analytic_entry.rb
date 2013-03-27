class AddAnalyticEntry < ActiveRecord::Migration

  def change

    create_table :analytic_repartitions do |t|
      t.references :activity,              :null=>false # lien avec une activité
      t.references :journal_entry_item,    :null=>false # lien avec une ligne d'une écriture comptable
      t.references :product_nature                      # lien avec un type de produit
      t.references :campaign                            # lien avec une campagne
      t.decimal    :repartition_percentage,    :null=>false, :precision=>16, :scale=>2 # % de repartition de la ligne sur l'activité
      t.date       :affected_on,           :null=>false # date de la repartition
      t.text       :description                         # description
      t.string     :state,           :null=>false       # etat (verouillé, en cours, en attente , esclave des opérations, maître des opérations)
      t.stamps
    end
    add_stamps_indexes :analytic_repartitions
    add_index :analytic_repartitions, :activity_id
    add_index :analytic_repartitions, :journal_entry_item_id
    add_index :analytic_repartitions, :product_nature_id
    add_index :analytic_repartitions, :campaign_id

  end

end
