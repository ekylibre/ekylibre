class NormalizeDeliveries < ActiveRecord::Migration
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
    change_column_null :deliveries, :transporter_id, true
    rename_column :deliveries, :departed_at, :started_at
    add_column :deliveries, :stopped_at, :datetime
    add_column :deliveries, :state, :string
    add_reference :deliveries, :driver, index: true
    add_column :deliveries, :mode, :string
    revert { add_column :deliveries, :net_mass, :decimal, precision: 19, scale: 4 }

    create_table :delivery_tools do |t|
      t.references :delivery, index: true
      t.references :tool, index: true
      t.stamps
    end

    create_table :parcels do |t|
      t.string :number, null: false
      t.string :nature, null: false
      t.string :reference_number
      t.references :recipient,   index: true
      t.references :sender,      index: true
      t.references :address,     index: true
      t.references :storage,     index: true
      t.references :delivery,    index: true
      t.references :sale,        index: true
      t.references :purchase,    index: true
      t.references :transporter, index: true
      t.boolean :remain_owner, null: false, default: false
      t.string :delivery_mode
      t.string :state, null: false
      t.datetime :planned_at
      t.datetime :ordered_at
      t.datetime :in_preparation_at
      t.datetime :prepared_at
      t.datetime :given_at
      t.integer :position
      t.stamps
      t.index :state
      t.index :number, unique: true
      t.index :nature
      # Temporary columns
      t.references :outgoing_parcel, index: true
      t.references :incoming_parcel, index: true
    end

    create_table :parcel_items do |t|
      t.references :parcel,         null: false, index: true
      t.references :sale_item,      index: true
      t.references :purchase_item,  index: true
      t.references :source_product, index: true
      t.references :product,        index: true
      t.references :analysis,       index: true
      t.references :variant,        index: true
      t.boolean :parted, null: false, default: false
      t.decimal :population, precision: 19, scale: 4
      t.geometry :shape, srid: 4326
      t.references :source_product_division,           index: true
      t.references :source_product_population_reading, index: true
      t.references :source_product_shape_reading,      index: true
      t.references :product_population_reading,        index: true
      t.references :product_shape_reading,             index: true
      t.references :product_enjoyment,                 index: true
      t.references :product_ownership,                 index: true
      t.references :product_localization,              index: true
      t.stamps
      # Temporary columns
      t.references :outgoing_parcel_item, index: true
      t.references :incoming_parcel_item, index: true
    end

    reversible do |dir|
      dir.up do
        execute "UPDATE deliveries SET state = CASE WHEN started_at IS NOT NULL THEN 'finished' ELSE 'in_preparation' END, mode = 'transporter'"
        execute "INSERT INTO parcels (number, nature, reference_number, given_at, recipient_id, address_id, delivery_id, sale_id, transporter_id, delivery_mode, state, outgoing_parcel_id, created_at, creator_id, updated_at, updater_id, lock_version) SELECT number, 'outgoing', reference_number, sent_at, recipient_id, address_id, delivery_id, sale_id, transporter_id, CASE WHEN with_transport THEN 'transporter' WHEN mode = 'ex_work' THEN 'third' ELSE 'us' END, CASE WHEN sent_at IS NOT NULL THEN 'given' WHEN transporter_id IS NOT NULL THEN 'in_preparation' ELSE 'ordered' END, id, created_at, creator_id, updated_at, updater_id, lock_version FROM outgoing_parcels"
        execute "INSERT INTO parcels (number, nature, reference_number, given_at, sender_id, address_id, purchase_id, delivery_mode, state, incoming_parcel_id, created_at, creator_id, updated_at, updater_id, lock_version) SELECT number, 'incoming', reference_number, received_at, sender_id, address_id, purchase_id, CASE WHEN mode = 'ex_work' THEN 'us' ELSE 'third' END, CASE WHEN received_at IS NOT NULL THEN 'given' ELSE 'in_preparation' END, id, created_at, creator_id, updated_at, updater_id, lock_version FROM incoming_parcels"

        execute 'INSERT INTO parcel_items (parcel_id, sale_item_id, source_product_id, parted, product_id, population, shape, outgoing_parcel_item_id, created_at, creator_id, updated_at, updater_id, lock_version) SELECT i.parcel_id, i.sale_item_id, i.product_id, i.parted, CASE WHEN i.parted THEN i.parted_product_id ELSE i.product_id END, i.population, i.shape, i.id, i.created_at, i.creator_id, i.updated_at, i.updater_id, i.lock_version FROM outgoing_parcel_items AS i JOIN parcels AS p ON (parcel_id = outgoing_parcel_id)'
        execute 'INSERT INTO parcel_items (parcel_id, purchase_item_id, source_product_id, product_id, population, shape, incoming_parcel_item_id, created_at, creator_id, updated_at, updater_id, lock_version) SELECT i.parcel_id, i.purchase_item_id, i.product_id, i.product_id, i.population, i.shape, i.id, i.created_at, i.creator_id, i.updated_at, i.updater_id, i.lock_version FROM incoming_parcel_items AS i JOIN parcels AS p ON (parcel_id = incoming_parcel_id)'

        execute 'UPDATE parcel_items SET variant_id = p.variant_id FROM products AS p WHERE p.id = parcel_items.product_id AND parcel_items.product_id IS NOT NULL'
        execute 'UPDATE parcel_items SET variant_id = p.variant_id FROM products AS p WHERE p.id = parcel_items.source_product_id AND parcel_items.source_product_id IS NOT NULL'
        execute 'UPDATE parcel_items SET variant_id = i.variant_id FROM sale_items AS i WHERE i.id = parcel_items.sale_item_id AND parcel_items.sale_item_id IS NOT NULL'
        execute 'UPDATE parcel_items SET variant_id = i.variant_id FROM purchase_items AS i WHERE i.id = parcel_items.purchase_item_id AND parcel_items.purchase_item_id IS NOT NULL'

        # Set storage on parcel and no more on each item
        execute "UPDATE parcels SET storage_id = container_id FROM outgoing_parcel_items AS i WHERE nature = 'outgoing' AND parcel_id = outgoing_parcel_id"
        execute "UPDATE parcels SET storage_id = container_id FROM incoming_parcel_items AS i WHERE nature = 'incoming' AND parcel_id = incoming_parcel_id"
        default_storage_id = select_value "SELECT id FROM products WHERE type IN ('Building', 'BuildingDivision') AND born_at IS NOT NULL AND dead_at IS NULL ORDER BY id DESC LIMIT 1"
        default_storage_id ||= select_value "SELECT id FROM products WHERE type IN ('BuildingDivision') AND born_at IS NOT NULL AND dead_at IS NULL ORDER BY id DESC LIMIT 1"
        default_storage_id ||= select_value "SELECT id FROM products WHERE type IN ('CultivableZone') AND born_at IS NOT NULL AND dead_at IS NULL ORDER BY id DESC LIMIT 1"
        if default_storage_id
          execute "UPDATE parcels SET storage_id = #{default_storage_id} WHERE storage_id IS NULL AND nature != 'outgoing'"
        end

        execute "UPDATE parcels SET state = 'draft' WHERE id NOT IN (SELECT parcel_id FROM parcel_items)"

        execute "INSERT INTO deliveries (mode, state, number, created_at, updated_at) SELECT 'third', 'finished', 'AUTO' || LPAD(id::VARCHAR, 8, '0'), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM parcels WHERE state = 'given' AND delivery_id IS NULL"
        execute "UPDATE parcels SET delivery_id = deliveries.id FROM deliveries WHERE deliveries.number = 'AUTO' || LPAD(parcels.id::VARCHAR, 8, '0')"

        POLYMORPHIC_REFERENCES.each do |table, reflection|
          execute "UPDATE #{table} SET #{reflection}_type = 'Parcel', #{reflection}_id = parcels.id FROM parcels WHERE (#{reflection}_type = 'IncomingParcel' AND incoming_parcel_id = #{reflection}_id) OR (#{reflection}_type = 'OutgoingParcel' AND outgoing_parcel_id = #{reflection}_id)"
          execute "UPDATE #{table} SET #{reflection}_type = 'ParcelItem', #{reflection}_id = parcel_items.id FROM parcel_items WHERE (#{reflection}_type = 'IncomingParcelItem' AND incoming_parcel_item_id = #{reflection}_id) OR (#{reflection}_type = 'OutgoingParcelItem' AND outgoing_parcel_item_id = #{reflection}_id)"
        end
      end
      dir.down do
        # execute "UPDATE outgoing_deliveries SET delivery_mode = CASE WHEN delivery_mode = 'third' THEN 'ex_work' ELSE delivered_at_place' END, with_transport = (delivery_mode = 'transporter')"
      end
    end

    revert do
      create_table 'incoming_parcel_items', force: :cascade do |t|
        t.integer 'parcel_id', null: false
        t.integer 'purchase_item_id'
        t.integer 'product_id', null: false
        t.decimal 'population', precision: 19, scale: 4
        t.integer 'container_id'
        t.datetime 'created_at',                                                                                     null: false
        t.datetime 'updated_at',                                                                                     null: false
        t.integer 'creator_id'
        t.integer 'updater_id'
        t.integer 'lock_version', default: 0, null: false
        t.geometry 'shape', limit: { srid: 4326, type: 'geometry' }
        t.decimal 'net_mass', precision: 19, scale: 4
      end

      add_index 'incoming_parcel_items', ['container_id'], name: 'index_incoming_parcel_items_on_container_id', using: :btree
      add_index 'incoming_parcel_items', ['created_at'], name: 'index_incoming_parcel_items_on_created_at', using: :btree
      add_index 'incoming_parcel_items', ['creator_id'], name: 'index_incoming_parcel_items_on_creator_id', using: :btree
      add_index 'incoming_parcel_items', ['parcel_id'], name: 'index_incoming_parcel_items_on_parcel_id', using: :btree
      add_index 'incoming_parcel_items', ['product_id'], name: 'index_incoming_parcel_items_on_product_id', using: :btree
      add_index 'incoming_parcel_items', ['purchase_item_id'], name: 'index_incoming_parcel_items_on_purchase_item_id', using: :btree
      add_index 'incoming_parcel_items', ['updated_at'], name: 'index_incoming_parcel_items_on_updated_at', using: :btree
      add_index 'incoming_parcel_items', ['updater_id'], name: 'index_incoming_parcel_items_on_updater_id', using: :btree

      create_table 'incoming_parcels', force: :cascade do |t|
        t.string 'number', null: false
        t.integer 'sender_id', null: false
        t.string 'reference_number'
        t.integer 'purchase_id'
        t.integer 'address_id'
        t.datetime 'received_at'
        t.datetime 'created_at',                                            null: false
        t.datetime 'updated_at',                                            null: false
        t.integer 'creator_id'
        t.integer 'updater_id'
        t.integer 'lock_version', default: 0, null: false
        t.decimal 'net_mass', precision: 19, scale: 4
        t.string 'mode'
      end

      add_index 'incoming_parcels', ['address_id'], name: 'index_incoming_parcels_on_address_id', using: :btree
      add_index 'incoming_parcels', ['created_at'], name: 'index_incoming_parcels_on_created_at', using: :btree
      add_index 'incoming_parcels', ['creator_id'], name: 'index_incoming_parcels_on_creator_id', using: :btree
      add_index 'incoming_parcels', ['purchase_id'], name: 'index_incoming_parcels_on_purchase_id', using: :btree
      add_index 'incoming_parcels', ['sender_id'], name: 'index_incoming_parcels_on_sender_id', using: :btree
      add_index 'incoming_parcels', ['updated_at'], name: 'index_incoming_parcels_on_updated_at', using: :btree
      add_index 'incoming_parcels', ['updater_id'], name: 'index_incoming_parcels_on_updater_id', using: :btree

      create_table 'outgoing_parcel_items', force: :cascade do |t|
        t.integer 'parcel_id', null: false
        t.integer 'sale_item_id'
        t.decimal 'population', precision: 19, scale: 4
        t.integer 'product_id', null: false
        t.datetime 'created_at',                                                                                          null: false
        t.datetime 'updated_at',                                                                                          null: false
        t.integer 'creator_id'
        t.integer 'updater_id'
        t.integer 'lock_version', default: 0, null: false
        t.geometry 'shape', limit: { srid: 4326, type: 'geometry' }
        t.decimal 'net_mass', precision: 19, scale: 4
        t.integer 'container_id'
        t.boolean 'parted', default: false, null: false
        t.integer 'parted_product_id'
      end

      add_index 'outgoing_parcel_items', ['container_id'], name: 'index_outgoing_parcel_items_on_container_id', using: :btree
      add_index 'outgoing_parcel_items', ['created_at'], name: 'index_outgoing_parcel_items_on_created_at', using: :btree
      add_index 'outgoing_parcel_items', ['creator_id'], name: 'index_outgoing_parcel_items_on_creator_id', using: :btree
      add_index 'outgoing_parcel_items', ['parcel_id'], name: 'index_outgoing_parcel_items_on_parcel_id', using: :btree
      add_index 'outgoing_parcel_items', ['product_id'], name: 'index_outgoing_parcel_items_on_product_id', using: :btree
      add_index 'outgoing_parcel_items', ['sale_item_id'], name: 'index_outgoing_parcel_items_on_sale_item_id', using: :btree
      add_index 'outgoing_parcel_items', ['updated_at'], name: 'index_outgoing_parcel_items_on_updated_at', using: :btree
      add_index 'outgoing_parcel_items', ['updater_id'], name: 'index_outgoing_parcel_items_on_updater_id', using: :btree

      create_table 'outgoing_parcels', force: :cascade do |t|
        t.string 'number', null: false
        t.integer 'recipient_id', null: false
        t.string 'reference_number'
        t.integer 'sale_id'
        t.integer 'address_id', null: false
        t.datetime 'sent_at'
        t.decimal 'net_mass', precision: 19, scale: 4
        t.integer 'delivery_id'
        t.integer 'transporter_id'
        t.datetime 'created_at',                                                null: false
        t.datetime 'updated_at',                                                null: false
        t.integer 'creator_id'
        t.integer 'updater_id'
        t.integer 'lock_version',                              default: 0,     null: false
        t.boolean 'with_transport',                            default: false, null: false
        t.string 'mode', null: false
      end

      add_index 'outgoing_parcels', ['address_id'], name: 'index_outgoing_parcels_on_address_id', using: :btree
      add_index 'outgoing_parcels', ['created_at'], name: 'index_outgoing_parcels_on_created_at', using: :btree
      add_index 'outgoing_parcels', ['creator_id'], name: 'index_outgoing_parcels_on_creator_id', using: :btree
      add_index 'outgoing_parcels', ['delivery_id'], name: 'index_outgoing_parcels_on_delivery_id', using: :btree
      add_index 'outgoing_parcels', ['number'], name: 'index_outgoing_parcels_on_number', using: :btree
      add_index 'outgoing_parcels', ['recipient_id'], name: 'index_outgoing_parcels_on_recipient_id', using: :btree
      add_index 'outgoing_parcels', ['sale_id'], name: 'index_outgoing_parcels_on_sale_id', using: :btree
      add_index 'outgoing_parcels', ['transporter_id'], name: 'index_outgoing_parcels_on_transporter_id', using: :btree
      add_index 'outgoing_parcels', ['updated_at'], name: 'index_outgoing_parcels_on_updated_at', using: :btree
      add_index 'outgoing_parcels', ['updater_id'], name: 'index_outgoing_parcels_on_updater_id', using: :btree
    end

    revert do
      add_reference :parcels, :outgoing_parcel, index: true
      add_reference :parcels, :incoming_parcel, index: true
      add_reference :parcel_items, :outgoing_parcel_item, index: true
      add_reference :parcel_items, :incoming_parcel_item, index: true
    end

    change_column_null :deliveries, :state, false
    # raise "Stop"
  end
end
