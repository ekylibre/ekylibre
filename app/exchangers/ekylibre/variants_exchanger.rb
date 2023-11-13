# frozen_string_literal: true

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
  # K: france maaid
  # L: accoutancy_category
  class VariantsExchanger < ActiveExchanger::Base
    category :settings
    vendor :ekylibre

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
            price_unity: s.cell('I', row).blank? ? nil : s.cell('I', row).to_s,
            indicators: s.cell('J', row).blank? ? {} : s.cell('J', row).to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each_with_object({}) do |i, h|
              h[i.first.strip.downcase.to_sym] = i.second
              h
            end,
            france_maaid: s.cell('K', row).blank? ? nil : s.cell('K', row).to_s.strip,
            category_name: s.cell('L', row).blank? ? nil : s.cell('L', row).to_s.strip,
            category_reference_name: s.cell('M', row).blank? ? nil : s.cell('M', row).to_s.strip.downcase.to_sym,
            category_product_account_number: s.cell('N', row).blank? ? nil : s.cell('N', row).to_s.strip,
            category_charge_account_number: s.cell('O', row).blank? ? nil : s.cell('O', row).to_s.strip
          }.to_struct

          unless r.reference_name
            w.warn "Need a reference to build variant for #{r.name}"
            next
          end
          # force import variant from lexicon or reference_nomenclature and update his attributes.
          if r.reference_name.to_s.start_with? '>'
            reference_name = r.reference_name[1..-1]
            if (nature_item = Onoma::ProductNature.find(reference_name))
              nature = ProductNature.import_from_nomenclature(reference_name)
              category = ProductNatureCategory.import_from_nomenclature(nature_item.category)
              variant = nature.variants.new(name: r.name, active: true, category: category)
            else
              raise 'Reference name not found in Product Nature Nomenclature: ' + r.reference_name.inspect
            end
          elsif r.france_maaid && (item = RegisteredPhytosanitaryProduct.find_by_id(r.france_maaid))
            variant = ProductNatureVariant.import_phyto_from_lexicon(item.reference_name)
          elsif MasterVariant.find_by_reference_name(r.reference_name)
            variant = ProductNatureVariant.import_from_lexicon(r.reference_name, true)
          elsif Onoma::ProductNatureVariant.find(r.reference_name)
            variant = ProductNatureVariant.import_from_nomenclature(r.reference_name, true)
          elsif (nature_item = Onoma::ProductNature.find(r.reference_name))
            nature = ProductNature.import_from_nomenclature(r.reference_name)
            category = ProductNatureCategory.import_from_nomenclature(nature_item.category)
            variant = nature.variants.new(name: r.name, active: true, category: category)
          else
            raise 'Invalid reference name: ' + r.reference_name.inspect
          end
          # update variant with attributes in the current row
          variant.name = r.name if r.name
          variant.work_number = r.work_number if r.work_number
          variant.default_unit_name ||= :unity
          variant.unit_name ||= :unit.tl
          variant.france_maaid = r.france_maaid if r.france_maaid
          if r.category_reference_name
            if ProductNatureCategory.find_by_name(r.category_name)
              category = ProductNatureCategory.find_by_name(r.category_name)
            else
              category = ProductNatureCategory.import_from_lexicon(r.category_reference_name, true)
              category.name = r.category_name
              category.save!
            end
            variant.category = category
          end
          variant.save!
          # update category with attributes
          if r.category_product_account_number
            variant.category.product_account = find_or_create_account(r.category_product_account_number, r.name)
          end
          if r.category_charge_account_number
            variant.category.charge_account = find_or_create_account(r.category_charge_account_number, r.name)
          end
          variant.category.save! if (r.category_product_account_number || r.category_charge_account_number)

          if r.indicators.any?
            r.indicators.each do |indicator_name, value|
              variant.read! indicator_name, value
            end
          end

          if r.price_unity
            unit = Unit.import_from_lexicon(r.price_unity.to_s)
            unless unit.present?
              raise ActiveExchanger::NotWellFormedFileError.new("Unknown unit #{unit.inspect} for variant #{variant.name.inspect}.")
            end

            conditioning_data = variant.guess_conditioning
            # create prices if exist
            [[r.purchase_unit_pretax_amount, :purchase], [r.stock_unit_pretax_amount, :stock], [r.sale_unit_pretax_amount, :sale]].each do |(price, nature)|
              if price
                catalog = Catalog.by_default!(nature)
                attributes = { catalog: catalog, all_taxes_included: false, amount: price, unit: unit, started_at: Time.now, currency: currency }
                variant.catalog_items.create!(attributes)
              end
            end
          end
        end
        w.check_point
      end
    end

    private

      # @param [String] acc_number
      # @param [String] acc_name
      # @return [Account]
      def find_or_create_account(acc_number, acc_name = nil)
        Maybe(find_or_create_account_by_number(acc_number, acc_name))
          .or_raise
      end

      # @param [String] acc_number
      # @param [String] acc_name
      # @return [Account]
      def find_or_create_account_by_number(acc_number, acc_name = nil)
        normalized = account_normalizer.normalize!(acc_number)

        Maybe(Account.find_by(number: normalized))
          .recover { create_account(acc_number, normalized, acc_name) }
          .or_raise
      end

      # @param [String] acc_number
      # @param [String] acc_name
      # @return [Account]
      def create_account(acc_number, acc_number_normalized, acc_name = nil)
        attrs = {
          name: acc_name,
          number: acc_number_normalized
        }
        Account.create!(attrs)
      end

    protected

      # @return [Accountancy::AccountNumberNormalizer]
      def account_normalizer
        @account_normalizer ||= Accountancy::AccountNumberNormalizer.build
      end

  end
end
