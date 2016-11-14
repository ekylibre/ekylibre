class AddStockAndMovementAccountsToStorableNomenclaturelessCategories < ActiveRecord::Migration
  ACCOUNT_LABELS = YAML.load <<-YAML
    :pt:
      :stock: Materiais diversos
      :stock_movement: Variação stocks diversos
    :fr:
      :stock: Matières diverses
      :stock_movement: Variations de stocks diverses
  YAML

  def change
    reversible do |dir|
      dir.up do
        %w(stock stock_movement).each do |account|
          # Find out what accounting plan we're using
          accounting_preference = execute("SELECT string_value FROM preferences WHERE name = 'accounting_preference'").first
          accounting_plan = accounting_preference && accounting_preference['string_value']

          case accounting_plan
          when /pt_snc/
            account_number = account =~ /stock$/ ? 3349 : 603
            label = ACCOUNT_LABELS[:pt][account.to_sym]
          else
            account_number = account =~ /stock$/ ? 329 : 6037
            label = ACCOUNT_LABELS[:fr][account.to_sym]
          end

          fitting_account = execute "SELECT * FROM accounts WHERE accounts.name = '#{account_number}'"
          if fitting_account.to_a.empty?
            execute 'INSERT INTO accounts (name, number, label, usages, created_at, updated_at) ' \
                    "  SELECT '#{account_number}', " \
                    "         '#{label}', " \
                    "         '#{account_number} - #{label}', " \
                    "         'stocks_variation'," \
                    '         CURRENT_TIMESTAMP,' \
                    '         CURRENT_TIMESTAMP'
          end
          account_id = execute("SELECT * FROM accounts WHERE accounts.name = '#{account_number}'").to_a.first['id']

          # Find storable categories w/o accounts
          execute 'UPDATE product_nature_categories' \
                  "  SET #{account}_account_id = #{account_id}" \
                  '  FROM product_nature_categories AS pnc' \
                  "  WHERE pnc.#{account}_account_id IS NULL" \
                  '    AND pnc.storable = TRUE'

          # Create missing stock accounts
          execute 'INSERT INTO accounts (name, number, label, usages, created_at, updated_at) ' \
                  '  SELECT sa.name || \' – \' || pnv.name, ' \
                  '    sa.number || pnv.number, sa.number || pnv.number || \' – \' || pnv.name, ' \
                  '    sa.usages, sa.created_at, sa.updated_at' \
                  '  FROM product_nature_variants AS pnv ' \
                  '    JOIN product_nature_categories AS pnc ON (pnv.category_id = pnc.id)' \
                  "    JOIN accounts AS sa ON (pnc.#{account}_account_id = sa.id)" \
                  '  WHERE sa.number IS NOT NULL'

          # Update stock account of variants
          execute 'UPDATE product_nature_variants AS pnv ' \
                  "  SET #{account}_account_id = sac.id " \
                  '  FROM product_nature_categories AS pnc ' \
                  "    JOIN accounts AS sa ON (pnc.#{account}_account_id = sa.id) " \
                  '    JOIN accounts AS sac ON (sa.usages = sac.usages AND sac.number LIKE sa.number || \'%\')' \
                  '  WHERE category_id = pnc.id AND sac.number = sa.number || pnv.number'
        end
      end
    end
  end
end
