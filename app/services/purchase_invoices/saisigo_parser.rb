# frozen_string_literal: true

module PurchaseInvoices
  class SaisigoParser

    VENDOR = 'saisigo'

    def initialize(document_id)
      @document = Document.find(document_id)
      @data = @document.klippa_metadata.deep_symbolize_keys
      @siren_number = @data[:fields][:supplier_siren].delete(' ')
      @company_informations = CompanyInformationsService.call(siren: @siren_number)
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
          # :taxe_amount=>"20.00",
          # :supplier_ref=>"168931",
          # :total_amount=>"39.18",
          # :total_amount_ttc=>"39.18"
          vat_percentage =  line[:taxe_amount].to_d
          infos = guess_line_info(line[:description], line[:supplier_ref], line[:unit], vat_percentage, supplier)
          items << { role: 'merchandise',
                      annotation: line[:description],
                      conditioning_quantity: line[:quantity].to_d,
                      conditioning_unit_id: infos[:unit].id,
                      tax_id: infos[:tax].id,
                      unit_pretax_amount: line[:gross_price].to_d,
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
        tax: guess_tax(vat, supplier),
        unit: guess_unit(unit)
      }
    end

    def guess_variant(title, supplier, ref)
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
      variant.update!(work_number: ref, name: title)
      variant
    end

    def guess_unit(unit_of_measurement)
      Unit.import_from_lexicon(:unity)
    end

    def guess_tax(percentage, supplier)
      tax = Tax.where(amount: percentage).first
      if tax.nil?
        tax = if (purchase_items=PurchaseItem.where(variant: variant)).any?
                purchase_items.order(id: :desc).first.tax
              elsif MasterVariantCategory.find_by_reference_name(variant.category.reference_name).present?
                Tax.where(amount: MasterVariantCategory.find_by_reference_name(variant.category.reference_name).default_vat_rate).first
              else
                Tax.last
              end
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
