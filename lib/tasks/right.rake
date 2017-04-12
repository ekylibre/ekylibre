task :right do
  partitions = {
    relationship: %w[districts entities events],
    accountancy: %w[accounts bank_statements cash_transfers cashes financial_years fixed_assets journal_draft journal_entries journals loans tax_declarations taxes],
    trade: %w[affairs catalogs contracts deposits gaps incoming_payment_modes incoming_payments outgoing_payment_lists outgoing_payment_modes outgoing_payments purchase_natures purchases sale_natures sales subscription_natures subscriptions],
    stocks: %w[incoming_deliveries inventories matters outgoing_deliveries product_nature_categories product_nature_variants product_natures transports],
    production: %w[activities analyses animal_groups animals building_divisions buildings campaigns cultivable_zones equipments fungi interventions issues land_parcels manure_management_plans plant_countings plants prescriptions product_groups productions products sensors settlements supervisions trackings wine_tanks workers],
    tools: %w[cap_statements documents exports imports georeadings guide_analyses guides listings],
    settings: %w[custom_fields document_templates integrations identifiers labels map_backgrounds net_services roles sequences settings teams users]
  }
  # %w(fungi gaps georeadings guide_analyses guides identifiers imports incoming_deliveries incoming_payment_modes incoming_payments integrations interventions inventories issues journal_draft journal_entries journals labels land_parcels listings loans manure_management_plans map_backgrounds matters myselves net_services observations outgoing_deliveries outgoing_payment_lists outgoing_payment_modes outgoing_payments plant_countings plants postal_zones prescriptions product_groups product_nature_categories product_nature_variants product_natures productions products purchase_natures purchases roles sale_natures sales sensors sequences settings settlements subscription_natures subscriptions supervisions tasks tax_declarations taxes teams trackings transports users wine_tanks workers)
  # first_run myselves
  resources = YAML.load_file('config/rights.yml')
  puts resources.keys.sort.join(' ')

  scopes = partitions.each_with_object({}) do |(part, res), h|
    h[part.to_s] = {
      'rights' => res.each_with_object({}) do |resource, i|
        i[resource.to_s] = {
          'rights' => resources[resource].each_with_object({}) do |(interaction, details), j|
            d = details.dup
            if d['dependencies']
              d['includes'] = d.delete('dependencies').map do |s|
                s.split('-').reverse.join(':')
              end
            end
            # d['resource'] = resource
            # d['interaction'] = interaction
            j["#{resource}:#{interaction}"] = d
            j
          end
        }
        i
      end
    }
    h
  end

  # resources.each do |resource, interactions|
  #   interactions.each do |interaction, details|
  #     d = details.dup
  #     if d['dependencies']
  #       d['includes'] = d.delete('dependencies').map do |s|
  #         s.split('-').join('_')
  #       end
  #     end
  #     d['resource'] = resource
  #     d['interaction'] = interaction
  #     d['part'] = %w(relationship accountancy sales purchases production tools settings).sample
  #     scopes["#{interaction}_#{resource}"] = d
  #   end
  # end
  File.write('rights.yml', scopes.to_yaml)
end
