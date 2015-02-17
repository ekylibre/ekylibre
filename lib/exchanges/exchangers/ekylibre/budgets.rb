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
    production_support_variant_reference_name = s.cell('E', 2)
    production_indicator_reference_name = s.cell('F', 2)
    production_indicator_unit_reference_name = s.cell('G', 2)

    # get budget concerning production (activty / given campaign)

    activity = Activity.find_or_create_by!(name: activity_name)
    campaign = Campaign.find_or_create_by!(harvest_year: campaign_harvest_year)
    production_variant = nil

    if production_variant_reference_name
      unless production_variant = ProductNatureVariant.find_by(number: production_variant_reference_name) || ProductNatureVariant.find_by(reference_name: production_variant_reference_name)
        production_variant = ProductNatureVariant.import_from_nomenclature(production_variant_reference_name)
      end
    end

    production = Production.find_or_create_by!(activity: activity, campaign: campaign, variant: production_variant)

    if production_support_variant_reference_name
      unless production_support_variant = ProductNatureVariant.find_by(number: production_support_variant_reference_name) || ProductNatureVariant.find_by(reference_name: production_support_variant_reference_name)
        production_support_variant = ProductNatureVariant.import_from_nomenclature(production_support_variant_reference_name)
      end
    end

    if production.support_variant.blank? and production_support_variant
      production.support_variant = production_support_variant
    end

    if production_indicator_reference_name and (production.working_indicator.blank? || production.working_indicator != production_indicator_reference_name.to_sym)
      production.working_indicator = production_indicator_reference_name.to_sym
    end

    if production_indicator_unit_reference_name and (production.working_unit.blank? || production.working_unit != production_indicator_unit_reference_name.to_sym)
      production.working_unit = production_indicator_unit_reference_name.to_sym
    end

    production.save!

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
      next if s.cell('A', row_number).blank?
      r = {
        item_code_variant: s.cell('B', row_number),
        computation_method: (s.cell('C', row_number).to_s.downcase == 'uo' ? :per_working_unit : (s.cell('C', row_number).to_s.downcase == 'support' ? :per_production_support : :per_production)),
        support_numbers: (s.cell('D', row_number).blank? ? nil : s.cell('D', row_number).to_s.strip.delete(' ').upcase.split(',')),
        item_quantity: (s.cell('E', row_number).blank? ? nil : s.cell('E', row_number).to_d),
        item_quantity_unity: (s.cell('F', row_number).blank? ? nil : s.cell('F', row_number).to_s),
        item_unit_price_amount: (s.cell('G', row_number).blank? ? nil : s.cell('G', row_number).to_d),
        item_direction: (s.cell('H', row_number).to_f == -1 ? :expense : :revenue)
      }.to_struct



      # get variant
      unless item_variant = ProductNatureVariant.find_by(number: r.item_code_variant) || ProductNatureVariant.find_by(reference_name: r.item_code_variant)
        if Nomen::ProductNatureVariants[r.item_code_variant]
          item_variant = ProductNatureVariant.import_from_nomenclature(r.item_code_variant)
        else
          puts "Cannot import budget line for: #{r.item_code_variant}".red
          next
        end
      end

      # Set budget
      budget = Budget.find_or_create_by!(variant: item_variant, production: production, direction: r.item_direction, unit_amount: r.item_unit_price_amount, computation_method: r.computation_method)
      if budget.per_production?
        budget.global_quantity = r.item_quantity
        budget.global_amount = budget.unit_amount * budget.global_quantity
      elsif r.support_numbers and (budget.per_working_unit? || budget.per_production_support?)
        # Get supports and existing production_supports
        supports = Product.where(work_number: r.support_numbers)
        # production_supports = ProductionSupport.of_campaign(campaign).where(storage_id: supports.pluck(:id))
        production_supports = ProductionSupport.of_campaign(campaign).where(storage: supports)
        # Set budget item for each production_support
        production_supports.each do |support|
          unless budget.items.find_by(production_support: support)
            budget.items.create!(production_support: support, quantity: r.item_quantity)
          end
        end
      end
      budget.save!

    end
    w.check_point
  end


end
