class AddStockAndMovementAccountsToStorableNomenclaturelessCategories < ActiveRecord::Migration
  ACCOUNT_LABELS = YAML.load <<-YAML
    :pt_snc:
      :stock:
        :label: Materiais diversos
        :number: 3349
      :stock_movement:
        :label: Variação stocks diversos
        :number: 603
    :fr_pcg82: &fr_pcg82
      :stock:
        :label: Matières diverses
        :number: 329
      :stock_movement:
        :label: 6037
        :number: Variations de stocks diverses
    :fr_pcga: *fr_pcg82
  YAML

  def change
    reversible do |dir|
      dir.up do
        # Find out what accounting plan we're using
        accounting_preference = execute("SELECT string_value FROM preferences WHERE name = 'accounting_system'").first
        return unless accounting_preference.present?
        accounting_plan = accounting_preference && accounting_preference['string_value'].to_sym
        %w(stock stock_movement).each do |account_type|
          @type = account_type.to_sym
          account_number = ACCOUNT_LABELS[accounting_plan][@type][:number]
          label = ACCOUNT_LABELS[accounting_plan][@type][:label]

          if concerned_categories_count.nonzero?
            fitting_account = find_account(account_number)
            create_account(account_number, label) unless fitting_account.present?
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
    execute("SELECT * FROM accounts WHERE accounts.name = '#{number}'").to_a.first
  end

  def concerned_categories_count
    results = execute 'SELECT COUNT(*)' \
                      '  FROM product_nature_categories AS pnc' \
                      "  WHERE pnc.#{@type}_account_id IS NULL" \
                      '    AND pnc.storable = TRUE'
    results.to_a.first['count'].to_i
  end

  def concerned_variants_count
    results = execute 'SELECT COUNT(*)' \
                      '  FROM product_nature_variants AS pnv ' \
                      '    JOIN product_nature_categories AS pnc ON pnc.id = pnv.category_id' \
                      "  WHERE pnc.storable = TRUE AND pnv.#{@type}_account_id IS NULL"
    results.to_a.first['count'].to_i
  end

  def create_missing_variant_accounts
    execute 'INSERT INTO accounts (name, number, label, usages, created_at, updated_at) ' \
            '  SELECT sa.name || \' – \' || pnv.name, ' \
            '    sa.number || pnv.number, sa.number || pnv.number || \' – \' || pnv.name, ' \
            '    sa.usages, sa.created_at, sa.updated_at' \
            '  FROM product_nature_variants AS pnv ' \
            '    JOIN product_nature_categories AS pnc ON (pnv.category_id = pnc.id)' \
            "    JOIN accounts AS sa ON (pnc.#{@type}_account_id = sa.id)" \
            '  WHERE sa.number IS NOT NULL' \
            '    AND pnc.storable = TRUE' \
            "    AND pnv.#{@type}_account_id IS NULL"
  end

  def reference_new_account_in_concerned_variants
    execute 'UPDATE product_nature_variants AS pnv ' \
            "  SET #{@type}_account_id = sac.id " \
            '  FROM product_nature_categories AS pnc ' \
            "    JOIN accounts AS sa ON (pnc.#{@type}_account_id = sa.id) " \
            '    JOIN accounts AS sac ON (sa.usages = sac.usages AND sac.number LIKE sa.number || \'%\')' \
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

  def reference_correct_account_in_concerned_categories(account)
    execute 'UPDATE product_nature_categories' \
            "  SET #{@type}_account_id = #{account}" \
            '  FROM product_nature_categories AS pnc' \
            "  WHERE pnc.#{@type}_account_id IS NULL" \
            '    AND pnc.storable = TRUE'
  end
end
