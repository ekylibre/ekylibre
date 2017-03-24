class UpdateFixedAssets < ActiveRecord::Migration
  ACCOUNT = (YAML.safe_load <<-YAML).deep_symbolize_keys.freeze
      name:
        fra: Immobilisations en cours
        eng: Outstanding assets
        por: Ativos em circulação
      number: 23
    YAML

  def change
    add_reference :purchase_items, :depreciable_product, index: true
    add_reference :purchase_items, :fixed_asset, index: true
    add_reference :fixed_assets, :product, index: true

    add_column :fixed_assets, :state, :string
    add_column :fixed_assets, :depreciation_period, :string
    add_column :fixed_assets, :accounted_at, :datetime
    add_reference :fixed_assets, :journal_entry, index: true
    add_reference :fixed_assets, :asset_account, index: true

    add_column :fixed_assets, :sold_on, :date
    add_column :fixed_assets, :scrapped_on, :date
    add_reference :fixed_assets, :sold_journal_entry, index: true
    add_reference :fixed_assets, :scrapped_journal_entry, index: true

    reversible do |r|
      r.up do
        language_pref = execute("SELECT preferences.* FROM preferences WHERE preferences.name = 'language' LIMIT 1").first
        language      = language_pref ? language_pref['string_value'].to_sym : :eng
        language      = (ACCOUNT[:name].keys & [language]).first || :eng
        name          = ACCOUNT[:name][language]
        number        = ACCOUNT[:number]
        label         = "#{name} - #{number}"

        execute "UPDATE fixed_assets SET depreciation_period = 'yearly'"
        execute 'UPDATE purchase_items pi SET fixed_asset_id = (SELECT fa.id FROM fixed_assets fa WHERE fa.purchase_item_id = pi.id LIMIT 1)'
        execute 'UPDATE fixed_assets fa SET product_id = (SELECT p.id FROM products p WHERE p.fixed_asset_id = fa.id LIMIT 1)'
        execute "UPDATE fixed_assets SET state = 'draft'"
        # set all account 21X on fixed asset from initial purchase entry item
        execute <<-SQL
          UPDATE fixed_assets AS fa
          SET asset_account_id = jei.account_id
          FROM journal_entry_items AS jei
          JOIN accounts AS a ON jei.account_id = a.id
          JOIN purchase_items AS pi ON pi.id = jei.resource_id
          WHERE jei.resource_type = 'PurchaseItem'
          AND jei.resource_prism = 'item_product'
          AND a.number LIKE '2%'
          AND fa.id = pi.fixed_asset_id
        SQL

        account_exists = execute('SELECT accounts.* FROM accounts WHERE (usages ~ E\'\\moutstanding_assets\\M\') ORDER BY accounts.id ASC LIMIT 1').first
        items_to_change = execute <<-SQL
          SELECT *
          FROM journal_entry_items AS jei
          JOIN purchase_items AS pi
          ON pi.id = jei.resource_id
          JOIN accounts AS a
          ON a.id = jei.account_id
          WHERE jei.resource_type = 'PurchaseItem'
            AND jei.resource_prism = 'item_product'
            AND pi.fixed_asset_id IS NOT NULL
            AND a.number LIKE '2%'
        SQL

        if items_to_change.any? && !account_exists
          execute "INSERT INTO accounts (name, number, usages, label, created_at, updated_at, lock_version)
                   VALUES ('#{name}', '#{number}', 'outstanding_assets', '#{label}',
                           '#{Time.zone.now}', '#{Time.zone.now}', 0)"
        end

        # replace all account (like 21X) by 23 on initial purchase entry item.
        execute <<-SQL
          UPDATE journal_entry_items AS jei
          SET account_id = (SELECT acc.id FROM accounts AS acc WHERE acc.usages = 'outstanding_assets' LIMIT 1)
          FROM purchase_items AS pi, accounts AS a
          WHERE pi.id = jei.resource_id
          AND a.id = jei.account_id
          AND jei.resource_type = 'PurchaseItem'
          AND jei.resource_prism = 'item_product'
          AND pi.fixed_asset_id IS NOT NULL
          AND a.number LIKE '2%'
        SQL

        execute "INSERT INTO preferences (name, nature, string_value, created_at, updated_at, lock_version)
                 VALUES ('default_depreciation_period', 'string', 'yearly', '#{Time.zone.now}', '#{Time.zone.now}', 0)"
      end
      r.down do
        execute "DELETE FROM preferences WHERE preferences.name = 'default_depreciation_period'"
        execute 'UPDATE fixed_assets fa SET purchase_item_id = (SELECT pi.id FROM purchase_items pi WHERE fa.id = pi.fixed_asset_id LIMIT 1)'
        execute 'UPDATE products p SET fixed_asset_id = (SELECT fa.id FROM fixed_assets fa WHERE fa.product_id = p.id LIMIT 1)'
      end
    end
  end
end
