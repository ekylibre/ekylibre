# coding: utf-8
# Create or updates equipments
Exchanges.add_importer :ekylibre_budgets do |file, w|

  s = Roo::OpenOffice.new(file)
  w.count = s.sheets.count

  s.sheets.each do |sheet_name|

    s.sheet(sheet_name)

    # get information for production context
    campaign_harvest_year = s.cell('A', 2)
    activity_name = s.cell('B',2)
    production_variant_reference_name = s.cell('D', 2)
    production_variant_support_reference_name = s.cell('E', 2)
    production_indicator_reference_name = s.cell('F', 2)
    production_indicator_unit_reference_name = s.cell('G', 2)

    # get budget concerning production (activty / given campaign)

    activity = Activity.where("name ILIKE ?", activity_name + '%').first
    campaign = Campaign.where(harvest_year: campaign_harvest_year).first

    if production_variant_reference_name
      unless production_variant = ProductNatureVariant.where(reference_name: production_variant_reference_name.to_sym).first
        production_variant = ProductNatureVariant.import_from_nomenclature(production_variant_reference_name.to_sym)
      end
      if production_variant_support_reference_name
        unless production_support_variant = ProductNatureVariant.where(reference_name: production_variant_support_reference_name.to_sym).first
          production_support_variant = ProductNatureVariant.import_from_nomenclature(production_variant_support_reference_name.to_sym)
        end
      end
      production = Production.where(activity: activity, campaign: campaign, variant: production_variant).first
    else
      production = Production.where(activity: activity, campaign: campaign).first
    end

    if production

      if production.support_variant.blank? and production_support_variant
        production.support_variant = production_support_variant
        production.save!
      end

      if production_indicator_reference_name and (production.working_indicator.blank? || production.working_indicator != production_indicator_reference_name.to_sym)
        production.working_indicator = production_indicator_reference_name.to_sym
        production.save!
      end

      if production_indicator_unit_reference_name and (production.working_unit.blank? || production.working_unit != production_indicator_unit_reference_name.to_sym)
        production.working_unit = production_indicator_unit_reference_name.to_sym
        production.save!
      end

      # file format
      # A "Nom de l'intervention ou de intrant"
      # B "Variant reference_name CF NOMENCLATURE"
      # C "Proportionnalité" vide = support ou production_indicator_unit_reference_name
      # D "Codes des supports travaillés [array] CF WORK_NUMBER"
      # E "Quantité"
      # F "Unité de la quantité CF NOMENCLATURE"
      # G "Prix TTC"
      # H "sens -1 = dépense / +1 = recette"

      # 3 first line are not budget items
      4.upto(s.last_row) do |row_number|
        next if s.cell('A',row_number).blank?
        r = {
          item_code_variant: s.cell('B',row_number),
          proportion: (s.cell('C',row_number).to_s.downcase == 'uo' ? :per_working_unit : (s.cell('C',row_number).to_s.downcase == 'support' ? :per_production_support : :per_production)),
          support_numbers: (s.cell('D',row_number).blank? ? nil : s.cell('D',row_number).to_s.strip.delete(' ').upcase.split(',')),
          item_quantity: (s.cell('E',row_number).blank? ? nil : s.cell('E',row_number).to_d),
          item_quantity_unity: (s.cell('F',row_number).blank? ? nil : s.cell('F',row_number).to_s),
          item_unit_price_amount: (s.cell('G',row_number).blank? ? nil : s.cell('G',row_number).to_d),
          item_direction: (s.cell('H',row_number).to_f == -1 ? :expense : :revenue)
        }.to_struct



        # get variant
        unless item_variant = ProductNatureVariant.where(reference_name: r.item_code_variant.to_sym).first
          item_variant = ProductNatureVariant.import_from_nomenclature(r.item_code_variant.to_sym)
        end

        # Set budget
        unless budget = Budget.where(variant: item_variant, production: production, direction: r.item_direction, unit_amount: r.item_unit_price_amount, computation_method: r.proportion).first
          budget = Budget.create!(variant: item_variant,
                                  production: production,
                                  direction: r.item_direction,
                                  unit_amount: r.item_unit_price_amount,
                                  computation_method: r.proportion
                                 )
        end

        if budget.computation_method == 'per_production'
          budget.global_quantity = r.item_quantity
          budget.global_amount = budget.unit_amount * budget.global_quantity
          budget.save!
        end

        # Get supports and existing production_supports
        if r.support_numbers and ( budget.computation_method == 'per_working_unit' || budget.computation_method == 'per_production_support' )
          supports = Product.where(work_number: r.support_numbers)
          production_supports = ProductionSupport.of_campaign(campaign).where(storage_id: supports.pluck(:id))
          # Set budget item for each production_support
          for ps in production_supports
            budget.items.create!(production_support: ps, quantity: r.item_quantity)
          end
        end

      end
    end
    w.check_point
  end




end
