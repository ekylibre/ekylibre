class SimplifyTaxes < ActiveRecord::Migration
  ASSET_TAXES = {
    french_vat_normal_asset_1966: :french_vat_normal_1966,
    french_vat_normal_asset_1982: :french_vat_normal_1982,
    french_vat_normal_asset_2000: :french_vat_normal_2000,
    french_vat_normal_asset_2014: :french_vat_normal_2014
  }.freeze

  def change
    add_column :taxes, :active, :boolean, null: false, default: false
    add_column :taxes, :nature, :string
    add_column :taxes, :country, :string
    add_reference :taxes, :fixed_asset_deduction_account, index: true
    add_reference :taxes, :fixed_asset_collect_account, index: true

    reversible do |d|
      d.up do
        # Adds missing "normal" VAT for "asset" VAT
        execute 'INSERT INTO taxes (name, amount, reference_name) SELECT name, amount, CASE ' +
                ASSET_TAXES.map { |a, n| "WHEN reference_name = '#{a}' THEN '#{n}'" }.join(' ') +
                " ELSE NULL END FROM taxes WHERE reference_name IN ('" + ASSET_TAXES.keys.join("', '") + "')" \
                ' AND reference_name NOT IN (SELECT CASE ' +
                ASSET_TAXES.map { |a, n| "WHEN reference_name = '#{n}' THEN '#{a}'" }.join(' ') +
                " ELSE 'toto' END FROM taxes)"

        # Updates normal with fixed asset
        execute 'UPDATE taxes SET fixed_asset_collect_account_id = a.collect_account_id, fixed_asset_deduction_account_id = a.deduction_account_id FROM taxes AS a WHERE ' + ASSET_TAXES.map { |a, n| "(taxes.reference_name = '#{n}' AND a.reference_name = '#{a}')" }.join(' OR ')

        # Removes fixed asset taxes
        execute "DELETE FROM taxes WHERE reference_name IN ('" + ASSET_TAXES.keys.join("', '") + "')"

        # Activate needed taxes
        execute "UPDATE taxes SET active = TRUE WHERE reference_name SIMILAR TO '%_201(1|2|3|4)' OR LENGTH(TRIM(reference_name)) <= 0"

        execute 'UPDATE taxes SET nature = CASE ' + %w[inflated intermediate reduced particular null].map { |n| "WHEN reference_name LIKE '%#{n}%' THEN '#{n}_vat'" }.join(' ') + " ELSE 'normal_vat' END, country = CASE WHEN reference_name LIKE 'spain%' THEN 'es' WHEN reference_name LIKE 'swiss%' THEN 'ch' ELSE 'fr' END"
      end
      d.down do
        # Adds "asset" VAT
        execute 'INSERT INTO taxes (name, amount, reference_name, deduction_account_id, collect_account_id) SELECT name, amount, CASE ' + ASSET_TAXES.map { |a, n| "WHEN reference_name = '#{n}' THEN '#{a}'" }.join(' ') + " ELSE NULL END, fixed_asset_deduction_account_id, fixed_asset_collect_account_id FROM taxes WHERE reference_name IN ('" + ASSET_TAXES.values.join("', '") + "') AND (fixed_asset_deduction_account_id IS NOT NULL OR fixed_asset_collect_account_id IS NOT NULL)"
      end
    end

    change_column_null :taxes, :nature, false
    change_column_null :taxes, :country, false
  end
end
