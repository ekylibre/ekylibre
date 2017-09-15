class AddPayslips < ActiveRecord::Migration
  POLYMORPHIC_KEYS = [
    %i[attachments resource],
    %i[calls source],
    %i[issues target],
    %i[journal_entries resource],
    %i[journal_entry_items resource],
    %i[notifications target],
    %i[observations subject],
    %i[preferences record_value],
    %i[product_enjoyments originator],
    %i[product_linkages originator],
    %i[product_links originator],
    %i[product_localizations originator],
    %i[product_memberships originator],
    %i[product_movements originator],
    %i[product_ownerships originator],
    %i[product_phases originator],
    %i[product_readings originator],
    %i[synchronization_operations originator],
    %i[versions item]
  ].freeze

  def change
    create_table :payslip_natures do |t|
      t.string :name, null: false
      t.string :currency, null: false
      t.boolean :active, null: false, default: false
      t.boolean :by_default, null: false, default: false
      t.boolean :with_accounting, null: false, default: false
      t.references :journal, null: false, index: true, foreign_key: true
      t.references :account, index: true, foreign_key: true
      t.stamps
      t.index :name, unique: true
    end

    create_table :payslips do |t|
      t.string :number, null: false
      t.references :nature, index: true, null: false
      t.references :employee, index: true
      t.references :account, index: true, foreign_key: true
      t.date :started_on, null: false
      t.date :stopped_on, null: false
      t.date :emitted_on
      t.string :state, null: false
      t.decimal :amount, precision: 19, scale: 4, null: false
      t.string :currency, null: false
      t.datetime :accounted_at
      t.references :journal_entry, index: true, foreign_key: true
      t.references :affair, index: true, foreign_key: true
      t.jsonb :custom_fields
      t.stamps
      t.index :number
      t.index :started_on
      t.index :stopped_on
    end
    add_foreign_key :payslips, :payslip_natures, column: :nature_id
    add_foreign_key :payslips, :entities, column: :employee_id

    change_column_default :outgoing_payments, :delivered, false
    change_column_default :outgoing_payments, :downpayment, false

    add_column :outgoing_payments, :type, :string
    reversible do |r|
      r.up do
        execute "UPDATE outgoing_payments SET type = 'PurchasePayment'"
        execute 'UPDATE outgoing_payments SET paid_at = CASE WHEN to_bank_at IS NOT NULL AND to_bank_at <= CURRENT_TIMESTAMP THEN to_bank_at ELSE created_at END WHERE delivered AND paid_at IS NULL'

        missing_ids = select_values('SELECT DISTINCT mode_id FROM outgoing_payments WHERE mode_id NOT IN (SELECT id FROM outgoing_payment_modes)')
        if missing_ids.any?
          execute "INSERT INTO outgoing_payment_modes (id, name, position, created_at, updated_at) SELECT id::INTEGER, 'Missing mode (ID=' || id::VARCHAR || ')', id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM regexp_split_to_table('#{missing_ids.join(',')}', ',') AS id"
        end

        missing_ids = select_values('SELECT DISTINCT payee_id FROM outgoing_payments WHERE payee_id NOT IN (SELECT id FROM entities)')
        if missing_ids.any?
          execute "INSERT INTO entities (id, active, locked, currency, language, nature, full_name, last_name, created_at, updated_at) SELECT id::INTEGER, false, true, 'EUR', 'fra', 'organization', 'Missing entity (ID=' || id::VARCHAR || ')', 'Missing entity (ID=' || id::VARCHAR || ')', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM regexp_split_to_table('#{missing_ids.join(',')}', ',') AS id"
        end

        execute 'UPDATE outgoing_payments SET list_id = NULL WHERE list_id NOT IN (SELECT id FROM outgoing_payment_lists)'

        execute 'UPDATE outgoing_payments SET journal_entry_id = NULL WHERE journal_entry_id NOT IN (SELECT id FROM journal_entries)'

        execute 'ALTER TABLE outgoing_payments ADD CONSTRAINT outgoing_payment_delivered CHECK ((delivered = FALSE) OR (delivered = TRUE AND paid_at IS NOT NULL))'
      end
      r.down do
        execute 'ALTER TABLE outgoing_payments DROP CONSTRAINT outgoing_payment_delivered'
      end
    end
    add_foreign_key :outgoing_payments, :outgoing_payment_modes, column: :mode_id, on_delete: :restrict
    add_foreign_key :outgoing_payments, :outgoing_payment_lists, column: :list_id
    add_foreign_key :outgoing_payments, :entities, column: :payee_id, on_delete: :restrict
    add_foreign_key :outgoing_payments, :journal_entries, column: :journal_entry_id

    reversible do |r|
      r.up do
        count = select_value("SELECT count(*) FROM purchase_natures WHERE nature = 'payslip'").to_i
        if count > 0
          account_id = find_or_create_staff_account_id

          add_column :payslip_natures, :purchase_nature_id, :integer
          # INFO: Conserve nature_id to prevent nature matching
          execute "INSERT INTO payslip_natures(purchase_nature_id, name, currency, active, with_accounting, account_id, journal_id, creator_id, created_at, updater_id, updated_at, lock_version) SELECT id, name, currency, active, with_accounting, #{account_id}, journal_id, creator_id, created_at, updater_id, updated_at, lock_version FROM purchase_natures WHERE nature = 'payslip'"
          execute 'UPDATE payslip_natures SET by_default = TRUE WHERE id IN (SELECT id FROM payslip_natures ORDER BY id LIMIT 1)'

          add_column :payslips, :purchase_id, :integer
          execute "INSERT INTO payslips(purchase_id, number, nature_id, employee_id, state, emitted_on, started_on, stopped_on, amount, currency, accounted_at, account_id, journal_entry_id, affair_id, creator_id, created_at, updater_id, updated_at, lock_version) SELECT p.id, p.number, n.id, supplier_id, CASE WHEN state = 'invoice' THEN 'invoice' ELSE 'draft' END, invoiced_at::DATE, invoiced_at::DATE, invoiced_at::DATE, amount, p.currency, accounted_at, #{account_id}, journal_entry_id, affair_id, p.creator_id, p.created_at, p.updater_id, p.updated_at, p.lock_version FROM purchases AS p JOIN payslip_natures AS n ON (n.purchase_nature_id = p.nature_id)"

          update_polymorphic_keys("SELECT purchase_id AS old_id, 'Purchase' AS old_type, id AS new_id, 'Payslip' AS new_type FROM payslips")

          execute "UPDATE affairs SET type = 'PayslipAffair' WHERE id IN (SELECT affair_id FROM payslips)"
          execute "UPDATE outgoing_payments SET type = 'PayslipPayment' WHERE affair_id IN (SELECT id FROM affairs WHERE type = 'PayslipAffair')"

          execute 'DELETE FROM purchase_items WHERE purchase_id IN (SELECT purchase_id FROM payslips)'
          execute 'DELETE FROM purchases WHERE id IN (SELECT purchase_id FROM payslips)'
          remove_column :payslips, :purchase_id

          update_polymorphic_keys("SELECT purchase_nature_id AS old_id, 'PurchaseNature' AS old_type, id AS new_id, 'PayslipNature' AS new_type FROM payslip_natures")

          execute "DELETE FROM purchase_natures WHERE nature = 'payslip'"
          remove_column :payslip_natures, :purchase_nature_id
        end
        execute "ALTER TABLE purchase_natures ADD CONSTRAINT purchase_natures_nature CHECK (nature = 'purchase')"
      end
      r.down do
        execute 'ALTER TABLE purchase_natures DROP CONSTRAINT purchase_natures_nature'

        count = select_value('SELECT count(*) FROM payslips').to_i
        if count > 0
          add_column :purchase_natures, :payslip_nature_id, :integer
          execute "INSERT INTO purchase_natures(payslip_nature_id, name, nature, with_accounting, journal_id, creator_id, created_at, updater_id, updated_at, lock_version) SELECT id, name, 'payslip', with_accounting, journal_id, creator_id, created_at, updater_id, updated_at, lock_version FROM payslip_natures"

          add_column :purchases, :payslip_id, :integer
          execute 'INSERT INTO purchases(payslip_id, nature_id, supplier_id, state, number, amount, currency, accounted_at, journal_entry_id, affair_id, creator_id, created_at, updater_id, updated_at, lock_version) SELECT id, n.id, employee_id, state, number, amount, p.currency, accounted_at, journal_entry_id, affair_id, p.creator_id, p.created_at, p.updater_id, p.updated_at, p.lock_version FROM payslips AS p JOIN purchase_natures AS n ON (p.nature_id = n.payslip_nature_id)'
          variant_id = find_or_create_worker_variant_id
          account_id = select_value("SELECT charge_account_id FROM product_nature_variants AS v JOIN product_nature_categories AS c ON (v.category_id = c.id) WHERE id = #{variant_id}").to_i
          tax_id = select_value("SELECT tax_id FROM product_nature_variants AS v JOIN product_nature_categories AS c ON (v.category_id = c.id) WHERE id = #{variant_id}").to_i
          execute "INSERT INTO purchase_items(purchase_id, variant_id, account_id, amount, pretax_amount, quantity, unit_amount, unit_pretax_amount, tax_id, creator_id, created_at, updater_id, updated_at, lock_version) SELECT p.id, #{variant_id}, #{account_id}, p.amount, p.amount, 1, p.amount, p.amount, #{tax_id}, p.creator_id, p.created_at, p.updater_id, p.updated_at, p.lock_version FROM purchases WHERE payslip_id IS NOT NULL"

          update_polymorphic_keys("SELECT payslip_id AS old_id, 'Payslip' AS old_type, id AS new_id, 'Purchase' AS new_type FROM purchases")

          remove_column :purchases, :payslip_id

          update_polymorphic_keys("SELECT payslip_nature_id AS old_id, 'PayslipNature' AS old_type, id AS new_id, 'PurchaseNature' AS new_type FROM purchase_natures")
          remove_column :purchase_natures, :payslip_nature_id
        end
      end
    end
  end

  def find_or_create_worker_variant_id
    variant_id = select_value("SELECT id FROM product_nature_variants WHERE variety = 'worker' LIMIT 1").to_i
    if variant_id.zero?
      nature_id = find_or_create_worker_nature_id
      number = (select_value('SELECT max(number::integer) FROM product_nature_variants AS pnvn').to_i + 1).rjust(6, '0')
      variant_id = select_value("INSERT INTO product_nature_variants (category_id, nature_id, variety, name, number, reference_name, unit_name, creator_id, created_at, updater_id, updated_at, lock_version) SELECT category_id, id, variety, 'Technician', '#{number}', 'technician', 'unit', creator_id, created_at, updater_id, updated_at, lock_version FROM product_natures WHERE id = #{nature_id} RETURNING id").to_i
    end
    variant_id
  end

  def find_or_create_worker_nature_id
    nature_id = select_value("SELECT id FROM product_natures WHERE variety = 'worker' ORDER BY id LIMIT 1").to_i
    if nature_id.zero?
      category_id = find_or_create_worker_category_id
      execute("INSERT INTO product_natures (category_id, population_counting, name, number, reference_name, variety, created_at, updated_at) SELECT #{category_id}, 'unitary', 'Staff', 'STAFF001', 'worker', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP")
      nature_id = select_value("SELECT id FROM product_natures WHERE variety = 'worker' ORDER BY id LIMIT 1").to_i
    end
    nature_id
  end

  def find_or_create_worker_category_id
    category_id = select_value("SELECT id FROM product_nature_categories WHERE reference_name = 'worker' ORDER BY id LIMIT 1").to_i
    if category_id.zero?
      charge_account_id = find_or_create_staff_account_id
      execute("INSERT INTO product_nature_categories (name, number, reference_name, charge_account_id, created_at, updated_at) SELECT 'Staff', 'ST001', 'staff', #{charge_account_id}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP")
      category_id = select_value("SELECT id FROM product_nature_categories WHERE reference_name = 'worker' ORDER BY id LIMIT 1").to_i
    end
    category_id
  end

  def find_or_create_staff_account_id
    account_id = select_value("SELECT id FROM accounts WHERE usages = 'staff_expenses' LIMIT 1").to_i
    if account_id.zero?
      execute("INSERT INTO accounts (name, number, label, usages, created_at, updated_at) SELECT 'Staff', '64', '64 - Staff', 'staff_expenses', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP")
      account_id = select_value("SELECT id FROM accounts WHERE usages = 'staff_expenses' LIMIT 1").to_i
    end
    account_id
  end

  # Updates types in polymorphic reflections with a conversion query which should
  # contains columns: old_id, old_type, new_id, new_type
  def update_polymorphic_keys(conversion_query)
    POLYMORPHIC_KEYS.each do |table, prefix|
      execute "UPDATE #{table} SET #{prefix}_type = x.new_type::VARCHAR, #{prefix}_id = x.new_id::INTEGER FROM (#{conversion_query}) AS x WHERE x.old_id::INTEGER = #{prefix}_id AND x.old_type::VARCHAR = #{prefix}_type"
    end
  end
end
