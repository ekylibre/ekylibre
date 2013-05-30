class GeneralizeObservations < ActiveRecord::Migration
  COMMENTEDS = [:accounts, :assets, :cash_transfers, :departments, :deposits, :entities, :entity_link_natures, :entity_links, :establishments, :incoming_deliveries, :incoming_delivery_modes, :inventories, :journal_entry_items, :listings, :outgoing_deliveries, :outgoing_delivery_modes, :product_groups, :product_indicator_nature_choices, :product_indicator_natures, :product_indicators, :product_nature_categories, :product_natures, :product_process_phases, :product_processes, :production_chain_conveyors, :production_chain_work_centers, :production_chains, :products, :purchase_natures, :purchases, :sale_natures, :sales, :subscription_natures, :subscriptions, :trackings, :transfers, :transports, :users]

  def up
    # remove_index :observations, :entity_id
    add_column :observations, :subject_type, :string
    add_column :observations, :observed_at, :datetime
    add_column :observations, :author_id, :integer
    rename_column :observations, :entity_id, :subject_id
    rename_column :observations, :description, :content
    execute("UPDATE #{quoted_table_name(:observations)} SET subject_type = 'Entity', observed_at = created_at, author_id = COALESCE(creator_id, 0)")
    change_column_null :observations, :subject_type, false
    change_column_null :observations, :observed_at, false
    change_column_null :observations, :author_id, false
    add_index :observations, [:subject_id, :subject_type]
    add_index :observations, :author_id

    # Removes all comment columns
    # t = []
    # for table in tables
    #   if column_exists?(table, :comment)
    #     x = table.to_s
    #     # x << "!" if column_exists?(table, :description)
    #     t << x.to_sym
    #   end
    # end
    # puts t.sort.map(&:inspect).join(', ')

    # TODO: Flatten migration when frozen by specifying tables names
    for table in tables
      if column_exists?(table, :comment)
        if column_exists?(table, :description)
          execute("INSERT INTO #{quoted_table_name(:observations)} (subject_type, subject_id, observed_at, author_id, created_at, creator_id, updated_at, updater_id) SELECT '#{table.classify}', id, created_at, COALESCE(creator_id, 0), created_at, creator_id, updated_at, updater_id FROM #{quoted_table_name(table)} WHERE LENGTH(TRIM(comment)) > 0")
          remove_column table, :comment
        else
          rename_column table, :comment, :description
        end
      end
    end
  end

end
