class ChangePanierLocalToSocleo < ActiveRecord::Migration[5.0]
  def up
    rename_nature_of_imports(from: 'panier_local', to: 'socleo')
    rename_provider_vendor(from: 'panier_local', to: 'socleo', in_tables: [
      'interventions',
      'accounts',
      'product_nature_categories',
      'incoming_payments',
      'sales',
      'fixed_assets',
      'sale_natures',
      'taxes',
      'loans',
      'entities',
      'incoming_payment_modes',
      'cashes',
      'journals',
      'catalogs',
      'product_nature_variants',
      'product_natures'
    ])
    rename_codes_key_of_entities(from: 'panier_local', to: 'socleo')
  end

  def down
    rename_nature_of_imports(from: 'socleo', to: 'panier_local')
    rename_provider_vendor(from: 'socleo', to: 'panier_local', in_tables: [
      'interventions',
      'accounts',
      'product_nature_categories',
      'incoming_payments',
      'sales',
      'fixed_assets',
      'sale_natures',
      'taxes',
      'loans',
      'entities',
      'incoming_payment_modes',
      'cashes',
      'journals',
      'catalogs',
      'product_nature_variants',
      'product_natures'
    ])
    rename_codes_key_of_entities(from: 'socleo', to: 'panier_local')
  end

  def rename_nature_of_imports(from:, to:)
    execute <<~SQL
      UPDATE imports
      SET nature = replace(nature, '#{from}', '#{to}')
      WHERE nature LIKE '%#{from}%';
    SQL
  end

  def rename_provider_vendor(from:, to:, in_tables:[])
    for table in in_tables
      execute <<~SQL
        UPDATE #{table}
        SET provider = jsonb_set(cast(provider as jsonb), '{vendor}', '"#{to}"')
        WHERE provider ->> 'vendor' = '#{from}';
      SQL
    end
  end

  def rename_codes_key_of_entities(from:, to:)
    execute <<~SQL
      UPDATE entities
      SET codes = replace(codes::TEXT,'#{from}','#{to}')::JSON
      WHERE codes::jsonb ? '#{from}'
    SQL
  end

end
