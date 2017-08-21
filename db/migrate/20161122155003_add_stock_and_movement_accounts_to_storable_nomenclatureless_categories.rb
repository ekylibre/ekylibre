# coding: utf-8

class AddStockAndMovementAccountsToStorableNomenclaturelessCategories < ActiveRecord::Migration
  ACCOUNT_LABELS = (YAML.safe_load <<-YAML
    pt_snc:
      stock:
        label: Materiais diversos
        number: 3349
      stock_movement:
        label: Variação stocks diversos
        number: 603
    fr_pcg82:
      stock:
        label: Matières diverses
        number: 329
      stock_movement:
        label: Variations de stocks diverses
        number: 6037
    fr_pcga:
      stock:
        label: Matières diverses
        number: 329
      stock_movement:
        label: Variations de stocks diverses
        number: 6037
  YAML
                   ).deep_symbolize_keys.freeze

  def change
    reversible do |dir|
      dir.up do
        # Find out what accounting plan we're using
        accounting_system = select_value("SELECT string_value FROM preferences WHERE name = 'accounting_system'")
        return if accounting_system.blank?
        accounting_system = accounting_system.to_sym
        %i[stock stock_movement].each do |account_type|
          @type = account_type
          account_number = ACCOUNT_LABELS[accounting_system][@type][:number]
          label = ACCOUNT_LABELS[accounting_system][@type][:label]
          if concerned_categories_count.nonzero?
            fitting_account = find_account(account_number)
            create_account(account_number, label) if fitting_account.blank?
            new_account_id = find_account(account_number)['id']

            # Find storable categories w/o accounts
            reference_correct_account_in_concerned_categories(new_account_id)
          end

          next if concerned_variants_count.zero?
          # Create missing stock accounts
          create_missing_variant_accounts
          # Update stock account of variants
          reference_new_account_in_concerned_variants
        end
      end
    end
  end

  def find_account(number)
    select_one("SELECT * FROM accounts WHERE accounts.number = '#{number}'")
  end

  def concerned_categories_count
    select_value('SELECT COUNT(*)' \
                 '  FROM product_nature_categories AS pnc' \
                 "  WHERE COALESCE(pnc.#{@type}_account_id, 0) NOT IN (SELECT id FROM accounts)" \
                 '    AND pnc.storable = TRUE').to_i
  end

  def concerned_variants_count
    select_value('SELECT COUNT(*)' \
                 '  FROM product_nature_variants AS pnv ' \
                 '    JOIN product_nature_categories AS pnc ON pnc.id = pnv.category_id' \
                 "  WHERE pnc.storable = TRUE AND COALESCE(pnv.#{@type}_account_id, 0) NOT IN (SELECT id FROM accounts)").to_i
  end

  def create_missing_variant_accounts
    execute 'INSERT INTO accounts (name, number, label, usages, created_at, updated_at) ' \
            '  SELECT pnca.name || \' – \' || pnv.name, ' \
            '    pnca.number || pnv.number, pnca.number || pnv.number || \' – \' || pnv.name, ' \
            '    pnca.usages, pnca.created_at, pnca.updated_at' \
            '  FROM product_nature_variants AS pnv ' \
            '    JOIN product_nature_categories AS pnc ON (pnv.category_id = pnc.id)' \
            "    JOIN accounts AS pnca ON (pnc.#{@type}_account_id = pnca.id)" \
            '  WHERE pnca.number IS NOT NULL' \
            '    AND pnc.storable = TRUE' \
            "    AND COALESCE(pnv.#{@type}_account_id, 0) NOT IN (SELECT id FROM accounts)" \
            '    AND pnca.number || pnv.number NOT IN (SELECT number FROM accounts)'
  end

  def reference_new_account_in_concerned_variants
    execute 'UPDATE product_nature_variants AS pnv ' \
            "  SET #{@type}_account_id = sac.id " \
            '  FROM product_nature_categories AS pnc ' \
            "    JOIN accounts AS sa ON (pnc.#{@type}_account_id = sa.id) " \
            "    JOIN accounts AS sac ON (sac.number = sa.number || '%')" \
            '  WHERE category_id = pnc.id AND sac.number = sa.number || pnv.number'
  end

  def create_account(number, label)
    execute 'INSERT INTO accounts (name, number, label, usages, created_at, updated_at) ' \
            "  SELECT '#{label}', " \
            "         '#{number}', " \
            "         '#{number} – #{label}', " \
            "         'stocks_variation'," \
            '         CURRENT_TIMESTAMP,' \
            '         CURRENT_TIMESTAMP'
  end

  def reference_correct_account_in_concerned_categories(account_id)
    execute 'UPDATE product_nature_categories' \
            "  SET #{@type}_account_id = #{account_id}" \
            '  FROM product_nature_categories AS pnc' \
            "  WHERE pnc.#{@type}_account_id IS NULL" \
            '    AND pnc.storable = TRUE'
  end
end
