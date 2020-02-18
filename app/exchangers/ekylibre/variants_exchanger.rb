# FIXME: Not absolute name. Rename to ProductNatureVariantsExchanger (don't forget nomenclature)
module Ekylibre
  # Expected file is a OpenDocument spreadsheet.
  # Columns are
  # A: Variant name in DB
  # B: reference_name (from ProductNatureVariant or ProductNature if not found)
  # C: Variant code in DB
  # D: Variety CF NOMENCLATURE
  # E: Derivative CF NOMENCLATURE
  # F: Purchase pretax amount price
  # G: Stock pretax amount price
  # H: Sale pretax amount price
  # I: Price unity
  # J: Indicators - HASH
  class VariantsExchanger < ActiveExchanger::Base
    # Create or updates variants
    def import
      currency = Preference[:currency] || 'EUR'

      s = Roo::OpenOffice.new(file)
      w.count = s.sheets.count

      s.sheets.each do |sheet_name|
        s.sheet(sheet_name)
        # first line are headers
        2.upto(s.last_row) do |row|
          next if s.cell('A', row).blank?
          r = {
            name: s.cell('A', row).blank? ? nil : s.cell('A', row).to_s.strip,
            reference_name: s.cell('B', row).blank? ? nil : s.cell('B', row).downcase.to_sym,
            work_number: s.cell('C', row).blank? ? nil : s.cell('C', row).to_s.strip,
            variety: s.cell('D', row).blank? ? nil : s.cell('D', row).to_s.strip,
            derivative_of: s.cell('E', row).blank? ? nil : s.cell('E', row).to_s.strip,
            purchase_unit_pretax_amount: s.cell('F', row).blank? ? nil : s.cell('F', row).to_d,
            stock_unit_pretax_amount: s.cell('G', row).blank? ? nil : s.cell('G', row).to_d,
            sale_unit_pretax_amount: s.cell('H', row).blank? ? nil : s.cell('H', row).to_d,
            price_unity: s.cell('I', row).blank? ? nil : s.cell('I', row).to_s.strip.split(/[\,\.\/\\\(\)]/),
            indicators: s.cell('J', row).blank? ? {} : s.cell('J', row).to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each_with_object({}) do |i, h|
              h[i.first.strip.downcase.to_sym] = i.second
              h
            end,
            france_maaid: s.cell('K', row).blank? ? nil : s.cell('K', row).to_s.strip
          }.to_struct

          unless r.reference_name
            w.warn "Need a reference to build variant for #{r.name}"
            next
          end
          # force import variant from reference_nomenclature and update his attributes.
          if r.reference_name.to_s.start_with? '>'
            reference_name = r.reference_name[1..-1]
            if nature_item = Nomen::ProductNature.find(reference_name)
              nature = ProductNature.import_from_nomenclature(reference_name)
              category = ProductNatureCategory.import_from_nomenclature(nature_item.category)
              type = category.article_type || nature.variant_type
              variant = nature.variants.new(name: r.name, active: true, category: category, type: type)
            end
          elsif Nomen::ProductNatureVariant.find(r.reference_name)
            variant = ProductNatureVariant.import_from_nomenclature(r.reference_name, true)
          elsif nature_item = Nomen::ProductNature.find(r.reference_name)
            nature = ProductNature.import_from_nomenclature(r.reference_name)
            category = ProductNatureCategory.import_from_nomenclature(nature_item.category)
            type = category.article_type || nature.variant_type
            variant = nature.variants.new(name: r.name, active: true, category: category, type: type)
          else
            raise 'Invalid reference name: ' + r.reference_name.inspect
          end
          # update variant with attributes in the current row
          variant.name = r.name if r.name
          variant.work_number = r.work_number if r.work_number
          variant.unit_name ||= :unit.tl
          variant.france_maaid = r.france_maaid if r.france_maaid
          variant.save!

          if r.indicators.any?
            r.indicators.each do |indicator_name, value|
              variant.read! indicator_name, value
            end
          end

          if r.price_unity
            # Find unit and matching indicator

            default_indicators = {
              mass: :net_mass,
              volume: :net_volume
            }.with_indifferent_access

            unit = r.price_unity.first

            if unit.present? && !Nomen::Unit[unit]
              if u = Nomen::Unit.find_by(symbol: unit)
                unit = u.name.to_s
                measure_unit_price = 1.00.in(unit.to_sym) if unit
              else
                raise ActiveExchanger::NotWellFormedFileError, "Unknown unit #{unit.inspect} for variant #{variant.name.inspect}."
              end
            end

            unless indicator = (unit.blank? ? :population : r.price_unity.second)
              dimension = Measure.dimension(unit)
              indics = variant.indicators.select do |indicator|
                next unless indicator.datatype == :measure
                Measure.dimension(indicator.unit) == dimension
              end.map(&:name)
              if indics.count > 1
                if indics.include?(default_indicators[dimension].to_s)
                  indicator = default_indicators[dimension]
                else
                  raise ActiveExchanger::NotWellFormedFileError, "Ambiguity on unit #{unit.inspect} for variant #{variant.name.inspect} between #{indics.to_sentence(locale: :eng)}. Cannot known what is wanted, insert indicator name after unit like: '#{unit} (#{indics.first})'."
                end
              elsif indics.empty?
                if unit == 'hour'
                  indicator = 'working_duration'
                else
                  raise ActiveExchanger::NotWellFormedFileError, "Unit #{unit.inspect} is invalid for variant #{variant.name.inspect}. No indicator can be used with this unit."
                end
              else
                indicator = indics.first
              end
            end
            # Find ratio to store the good price link to existing variant indicator
            variant_default_population = variant.send(indicator.to_sym)
            ratio = (variant_default_population.to_d(unit.to_sym) / measure_unit_price.to_d(unit.to_sym)).to_d
          else
            ratio = 1.0
          end

          # create a purchase price if needed
          if r.purchase_unit_pretax_amount
            catalog = Catalog.by_default!(:purchase)
            variant.catalog_items.create!(catalog: catalog, all_taxes_included: false, amount: (r.purchase_unit_pretax_amount * ratio), currency: currency)
          end
          # create a stock price if needed
          if r.stock_unit_pretax_amount
            catalog = Catalog.by_default!(:stock)
            if variant.catalog_items.where(catalog: catalog).empty?
              variant.catalog_items.create!(catalog: catalog, all_taxes_included: false, amount: r.stock_unit_pretax_amount * ratio, currency: currency)
            end
          end
          # create a sale price if needed
          next unless r.sale_unit_pretax_amount
          catalog = Catalog.by_default!(:sale)
          if variant.catalog_items.where(catalog: catalog).empty?
            variant.catalog_items.create!(catalog: catalog, all_taxes_included: false, amount: r.sale_unit_pretax_amount * ratio, currency: currency)
          end
        end
        w.check_point
      end
    end
  end
end
