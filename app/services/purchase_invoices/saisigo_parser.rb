# frozen_string_literal: true

module PurchaseInvoices
  class SaisigoParser

    VENDOR = 'saisigo'

    def initialize(document_id)
      @document = Document.find(document_id)
      @data = @document.klippa_metadata.deep_symbolize_keys
      if @data[:fields][:supplier_siren].present?
        @siren_or_siret_number = @data[:fields][:supplier_siren].delete(' ')
        if @siren_or_siret_number.length == 9
          @company_informations = CompanyInformationsService.call(siren: @siren_or_siret_number, siret: nil)
        elsif @siren_or_siret_number.length == 14
          @company_informations = CompanyInformationsService.call(siret: @siren_or_siret_number, siren: nil)
        end
      end
      @data[:partners].each do |e|
        @supplier_data = e if e[:role] == 'SP'
        @client_data = e if e[:role] == 'BI'
      end
    end

    # return an Entity
    def parse_and_create_invoice
      supplier = find_supplier || create_supplier
      unless supplier
        puts "No supplier found and error on created".inspect.red
        return nil
      end
      invoiced_at = Date.parse(@data[:fields][:invoice_date]).to_time if @data[:fields][:invoice_date].present?
      unless invoiced_at
        puts "Purchasedate not present".inspect.red
        return nil
      end
      purchase = PurchaseInvoice.new(
        planned_at: invoiced_at,
        invoiced_at: invoiced_at,
        reference_number: @data[:fields][:supplier_invoice_number],
        currency: @data[:fields][:currency],
        supplier: supplier,
        nature: PurchaseNature.actives.first
      )
      clean_lines = build_lines(invoiced_at, supplier)
      if purchase && clean_lines.any?
        clean_lines.each do |item|
          purchase.items.new(item)
        end
      end
      if purchase.save!
        purchase.attachments.create!(document: @document)
        purchase.id
      else
        puts purchase.errors.full_messages.inspect.red
        nil
      end
    end

    # build lines items
    def build_lines(invoiced_at, supplier)
      items = []
      if @data[:items].any?
        @data[:items].each do |line|
          # :unit=>"PCE",
          # :quantity=>"3",
          # :description=>"ROBINET DEGUSTATEUR VIS 1/2 SIMPLE",
          # :gross_price=>"13.06",
          # :taxe_amount=>"20.00" or "20.00 %",
          # :supplier_ref=>"168931",
          # :total_amount=>"39.18",
          # :total_amount_ttc=>"39.18"
          qty = ( line[:quantity].present? ? clean_number(line[:quantity]) : 1.0 )
          unit_pretax_amount = (line[:net_price].present? ? clean_number(line[:net_price]) : nil)
          unit_pretax_amount ||= (line[:gross_price].present? ? clean_number(line[:gross_price]) : nil)
          pretax_amount = clean_number(line[:total_amount])
          line_tax_amount = ( line[:taxe_amount].present? ? clean_number(line[:taxe_amount]) : 0.0 )
          if pretax_amount.present?
            vat_percentage = detect_line_vat_rate(line_tax_amount, pretax_amount)
          end
          vat_percentage ||= ( line[:item_vat_code].present? ? clean_number(line[:item_vat_code]) : 0.0 )
          if detect_global_vat_rate && vat_percentage == 0.0
            vat_percentage = detect_global_vat_rate
          end
          infos = guess_line_info(line[:description], line[:supplier_ref], line[:unit], vat_percentage, supplier)
          clean_unit_pretax_amount = fix_price(unit_pretax_amount, pretax_amount, qty)
          items << { role: 'merchandise',
                      annotation: line[:description],
                      conditioning_quantity: qty,
                      conditioning_unit_id: infos[:unit].id,
                      tax_id: infos[:tax].id,
                      unit_pretax_amount: clean_unit_pretax_amount,
                      variant_id: infos[:variant].id,
                      fixed: false }
        end
      end
      items
    end

    def guess_line_info(title, ref, unit, vat, supplier)
      variant = ProductNatureVariant.find_by(work_number: ref)
      variant ||= guess_variant(title, supplier, ref)
      infos = {
        variant: variant,
        tax: guess_tax(vat, variant),
        unit: guess_unit(unit)
      }
    end

    def fix_price(unit_pretax_amount, pretax_amount, qty)
      clean_unit_pretax_amount = unit_pretax_amount
      if (qty * unit_pretax_amount) != pretax_amount
        clean_unit_pretax_amount = (pretax_amount / qty).round(2)
      end
      clean_unit_pretax_amount
    end

    def detect_global_vat_rate
      rate = nil
      total_amount = ( @data[:fields][:total_incl_vat].present? ? clean_number(@data[:fields][:total_incl_vat]) : 0.0 )
      total_pretax_amount = ( @data[:fields][:total_wo_taxes].present? ? clean_number(@data[:fields][:total_wo_taxes]) : 0.0 )
      vat_amount = total_amount - total_pretax_amount
      if vat_amount > 0.0
        rate = ((vat_amount / total_pretax_amount) * 100)
      end
      rate
    end

    def detect_line_vat_rate(vat_amount, pretax_amount)
      rate = nil
      if vat_amount > 0.0 && pretax_amount > 0.0
        rate = ((vat_amount / pretax_amount) * 100)
      end
      rate
    end

    def guess_variant(title, supplier, ref)
      variant = ProductNatureVariant.where('providers ->> ? = ?', supplier.id.to_s, ref).first
      return variant if variant

      article = Duke::Skill::DukeArticle.new(user_input: title, supplier: supplier)
      products = Duke::DukeMatchingArray.new
      article.extract_user_specifics(duke_json: { supplier_article: products })
      if (product=article.supplier_article.max).present?
        variant = ProductNatureVariant.find(product.key)
      else
        article.extract_user_specifics(duke_json: { product_nature_variant: products })
        if (product=article.product_nature_variant.max).present?
          variant = ProductNatureVariant.find(product.key)
        else
          article.extract_user_specifics(duke_json: { lexicon_article: products })
          if (product=article.lexicon_article.max).present?
            variant = ProductNatureVariant.import_from_lexicon(product.key)
          else
            variant = ProductNatureVariant.import_from_lexicon('additional_activity')
          end
        end
      end
      existing_providers = variant.providers || {}
      existing_providers.merge!(supplier.id.to_s => ref)
      variant.update!(providers: existing_providers)
      variant
    end

    def guess_unit(unit_of_measurement)
      Unit.import_from_lexicon(:unity)
    end

    def clean_number(line)
      line.delete("^0-9^,^.").to_d
    end

    def guess_tax(percentage, variant)
      unless percentage.is_a?(Numeric)
        percentage = percentage.delete("^0-9^,").to_d
      end
      tax = Tax.usable_in_budget.where(amount: percentage).first
      if tax.nil? && variant.present?
        tax = if (purchase_items=PurchaseItem.where(variant: variant)).any?
                purchase_items.order(id: :desc).first.tax
              elsif MasterVariantCategory.find_by_reference_name(variant.category.reference_name).present?
                Tax.usable_in_budget.where(amount: MasterVariantCategory.find_by_reference_name(variant.category.reference_name).default_vat_rate).first
              else
                Tax.usable_in_budget.first
              end
      elsif tax.nil?
        tax = Tax.usable_in_budget.first
      end
      tax
    end

    # find an Entity
    def find_supplier
      # NAME
      entity = Entity.where('full_name ILIKE ?', @company_informations[:company_name]).first if @company_informations[:company_name].present?

      # VAT NUMBER
      entity ||= Entity.find_by(vat_number: @company_informations[:vat_number]) if @company_informations[:vat_number].present?

      # SIRET
      entity ||= Entity.find_by(siret_number: @company_informations[:siret_number]) if @company_informations[:siret_number].present?

      # EMAIL
      # ea = EntityAddress.find_by(canal: :email, coordinate: @data[:merchant_email].lower) if @data[:merchant_email].present?
      # entity ||= Entity.find_by(id: ea.entity_id) if ea

      # WEBSITE
      # ea = EntityAddress.find_by(canal: :website, coordinate: @data[:merchant_website].lower) if @data[:merchant_website].present?
      # entity ||= Entity.find_by(id: ea.entity_id) if ea

      # ZIPCODE & CITY
      line_6 = @company_informations[:city] if @company_informations[:city].present?
      ea = EntityAddress.find_by(canal: :mail, mail_line_6: line_6) if line_6.present?
      entity ||= Entity.find_by(id: ea.entity_id) if ea

      if entity.present?
        # autocomplete informations if missing
        entity.bank_identifier_code ||= @data[:fields][:swift] if @data[:fields][:swift].present?
        entity.iban ||= @data[:fields][:iban] if @data[:fields][:iban].present?
        if @company_informations.any?
          entity.siret_number ||= @company_informations[:siret_number] if @company_informations[:siret_number].present?
          entity.vat_number ||= @company_informations[:vat_number] if @company_informations[:vat_number].present?
          entity.activity_code ||= @company_informations[:activity_code] if @company_informations[:activity_code].present?
          entity.born_at ||= @company_informations[:company_creation_date].to_time if @company_informations[:company_creation_date].present?
        end
        entity.save!
        create_default_mail_address(entity)
        create_default_email_address(entity)
        create_default_phone_address(entity)
        create_default_website_address(entity)
        entity
      else
        nil
      end
    end

    # create an Entity
    def create_supplier
      if @supplier_data[:name1].present? && @company_informations.any?
        entity = Entity.new
        entity.nature = :organization
        entity.active = true
        entity.supplier = true
        entity.last_name = @company_informations[:company_name]
        entity.bank_identifier_code = @data[:fields][:swift] if @data[:fields][:swift].present?
        entity.iban = @data[:fields][:iban] if @data[:fields][:iban].present?
        # complete informations with SIRENE v3 API
        entity.siret_number = @company_informations[:siret_number] if @company_informations[:siret_number].present?
        entity.vat_number = @company_informations[:vat_number] if @company_informations[:vat_number].present?
        entity.activity_code = @company_informations[:activity_code] if @company_informations[:activity_code].present?
        entity.born_at = @company_informations[:company_creation_date].to_time if @company_informations[:company_creation_date].present?
        # end SIRENE v3 API
        entity.save!
        create_default_mail_address(entity)
        create_default_email_address(entity)
        create_default_phone_address(entity)
        create_default_website_address(entity)
        entity
      else
        nil
      end
    end

    def create_default_mail_address(entity)
      if @company_informations[:address].present? && @company_informations[:city].present?
        # create mail address from metadata
        line_6 = @company_informations[:city]
        line_4 = @company_informations[:address]
        attrs = { by_default: true, mail_line_6: line_6, mail_country: 'fr' }
        attrs[:mail_line_4] = line_4 if line_4.present?
        if line_6.present? && !entity.mails.where('mail_line_6 ILIKE ?', line_6).where(mail_country: 'fr').any?
          entity.mails.create!(attrs)
        end
      else
        nil
      end
    end

    def create_default_email_address(entity)
      if entity && @supplier_data[:email].present?
        unless entity.emails.where(coordinate: @supplier_data[:email].lower).any?
          entity.emails.create!(by_default: true, coordinate: @supplier_data[:email].lower)
        end
      end
    end

    def create_default_phone_address(entity)
      if entity && @supplier_data[:tel].present?
        unless entity.phones.where(coordinate: @supplier_data[:tel].lower).any?
          entity.phones.create!(by_default: true, coordinate: @supplier_data[:tel].lower)
        end
      end
    end

    def create_default_website_address(entity)
      if entity && @supplier_data[:website].present?
        unless entity.websites.where(coordinate: @supplier_data[:website].lower).any?
          entity.websites.create!(by_default: true, coordinate: @supplier_data[:website].lower)
        end
      end
    end

  end
end
