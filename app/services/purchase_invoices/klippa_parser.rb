# frozen_string_literal: true

module PurchaseInvoices
  class KlippaParser

    VENDOR = 'klippa'

    def initialize(document_id)
      @document = Document.find(document_id)
      @data = @document.klippa_metadata.deep_symbolize_keys
      @sirene = get_entity_on_sirene_v3(@data[:merchant_coc_number]) if @data[:merchant_coc_number].present? && @data[:merchant_country_code].present? && @data[:merchant_country_code] == 'FR'
    end

    # return an Entity
    def parse_and_create_invoice
      supplier = find_supplier || create_supplier
      unless supplier
        puts "No supplier found and error on created".inspect.red
        return nil
      end
      invoiced_at = Date.parse(@data[:purchasedate]).to_time if @data[:purchasedate].present?
      unless invoiced_at
        puts "Purchasedate not present".inspect.red
        return nil
      end
      purchase = PurchaseInvoice.new(
        planned_at: invoiced_at,
        invoiced_at: invoiced_at,
        reference_number: @data[:invoice_number],
        currency: @data[:currency],
        supplier: supplier,
        nature: PurchaseNature.actives.first,
        description: ( @data[:document_subject].present? ? @data[:document_subject] : nil )
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
      if @data[:lines].any?
        @data[:lines].first[:lineitems].each do |line|
          # :title=>"057424 STRATEMAIL FW ROUGE 1L 1 PCE\n0087671812 24/09/2021 928 Votre Réf.",
          # :description=>"",
          # :amount=>2927,
          # :amount_each=>2927,
          # :amount_ex_vat=>2927,
          # :vat_amount=>0,
          # :vat_percentage=>0,
          # :quantity=>1,
          # :unit_of_measurement=>"",
          # :sku=>"",
          # :vat_code=>""
          if detect_global_vat_rate && line[:vat_percentage].to_d == 0.0
            vat_percentage = detect_global_vat_rate
          else
            vat_percentage =  line[:vat_percentage].to_d
          end
          infos = guess_line_info(line[:title], line[:unit_of_measurement], vat_percentage, supplier)
          items << { role: 'merchandise',
                      annotation: line[:title],
                      conditioning_quantity: line[:quantity].to_d,
                      conditioning_unit_id: infos[:unit].id,
                      tax_id: infos[:tax].id,
                      unit_pretax_amount: (line[:amount_each].to_d / 100),
                      variant_id: infos[:variant].id,
                      fixed: false }
        end
      end
      items
    end

    def guess_line_info(title, unit, vat, supplier)
      variant = guess_variant(title, supplier)
      infos = {
        variant: variant,
        tax: guess_tax(vat, supplier),
        unit: guess_unit(unit)
      }
    end

    def detect_global_vat_rate
      rate = nil
      if @data[:vatamount].present? && @data[:amountexvat].present? && @data[:vatamount].to_d > 0.0
        rate = ((@data[:vatamount].to_d / @data[:amountexvat].to_d) * 100)
      end
      rate
    end

    def guess_variant(title, supplier)
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
      entity = Entity.where('full_name ILIKE ?', @data[:merchant_name].strip).first if @data[:merchant_name].present?

      # VAT NUMBER
      entity ||= Entity.find_by(vat_number: @data[:merchant_vat_number]) if @data[:merchant_vat_number].present?

      # SIRET
      entity ||= Entity.find_by(siret_number: @data[:merchant_coc_number]) if @data[:merchant_coc_number].present?

      # EMAIL
      ea = EntityAddress.find_by(canal: :email, coordinate: @data[:merchant_email].lower) if @data[:merchant_email].present?
      entity ||= Entity.find_by(id: ea.entity_id) if ea

      # WEBSITE
      ea = EntityAddress.find_by(canal: :website, coordinate: @data[:merchant_website].lower) if @data[:merchant_website].present?
      entity ||= Entity.find_by(id: ea.entity_id) if ea

      # ZIPCODE & CITY
      line_6 = @data[:merchant_zipcode] + ' ' + @data[:merchant_city] if @data[:merchant_zipcode].present? && @data[:merchant_city].present?
      ea = EntityAddress.find_by(canal: :mail, mail_line_6: line_6, mail_country: @data[:merchant_country_code].lower) if line_6.present?
      entity ||= Entity.find_by(id: ea.entity_id) if ea

      if entity.present?
        # autocomplete informations if missing
        entity.bank_identifier_code ||= @data[:merchant_bank_account_number_bic] if @data[:merchant_bank_account_number_bic].present?
        entity.iban ||= @data[:merchant_bank_account_number] if @data[:merchant_bank_account_number].present?
        if @sirene.present?
          entity.vat_number ||= @sirene[:vat_number] if @sirene[:vat_number].present?
          entity.activity_code ||= @sirene[:activity_code] if @sirene[:activity_code].present?
          entity.born_at ||= Date.parse(@sirene[:created_on]).to_time if @sirene[:created_on].present?
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
      if @data[:merchant_name].present?
        entity = Entity.new
        entity.nature = :organization
        entity.active = true
        entity.supplier = true
        entity.last_name = @data[:merchant_name]
        entity.bank_identifier_code = @data[:merchant_bank_account_number_bic] if @data[:merchant_bank_account_number_bic].present?
        entity.iban = @data[:merchant_bank_account_number] if @data[:merchant_bank_account_number].present?
        entity.vat_number = @data[:merchant_vat_number] if @data[:merchant_vat_number].present?
        entity.siret_number = @data[:merchant_coc_number] if @data[:merchant_coc_number].present?
        # complete informations with SIRENE v3 API
        if @sirene.present?
          entity.vat_number ||= @sirene[:vat_number] if @sirene[:vat_number].present?
          entity.activity_code ||= @sirene[:activity_code] if @sirene[:activity_code].present?
          entity.born_at ||= Date.parse(@sirene[:created_on]).to_time if @sirene[:created_on].present?
        end
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
      if @data[:merchant_country_code].present?
        # create mail address from metadata
        if entity && @data[:merchant_zipcode].present? && @data[:merchant_city].present?
          line_6 = @data[:merchant_zipcode] + ' ' + @data[:merchant_city]
          line_4 = @data[:merchant_address]
          attrs = { by_default: true, mail_line_6: line_6, mail_country: @data[:merchant_country_code].lower }
          attrs[:mail_line_4] = line_4 if line_4.present?
        # create mail address from entity siret and SIRENE v3 API
        elsif entity && @sirene.present?
          line_6 = @sirene[:postal_code] + ' ' + @sirene[:town]
          line_4 = @sirene[:address]
          attrs = { by_default: true, mail_line_6: line_6, mail_country: @data[:merchant_country_code].lower }
          attrs[:mail_line_4] = line_4 if line_4.present?
        end
        if line_6.present? && !entity.mails.where('mail_line_6 ILIKE ?', line_6).where(mail_country: @data[:merchant_country_code].lower).any?
          entity.mails.create!(attrs)
        end
      else
        nil
      end
    end

    def create_default_email_address(entity)
      if entity && @data[:merchant_email].present?
        unless entity.emails.where(coordinate: @data[:merchant_email].lower).any?
          entity.emails.create!(by_default: true, coordinate: @data[:merchant_email].lower)
        end
      end
    end

    def create_default_phone_address(entity)
      if entity && @data[:merchant_phone].present?
        unless entity.phones.where(coordinate: @data[:merchant_phone].lower).any?
          entity.phones.create!(by_default: true, coordinate: @data[:merchant_phone].lower)
        end
      end
    end

    def create_default_website_address(entity)
      if entity && @data[:merchant_website].present?
        unless entity.websites.where(coordinate: @data[:merchant_website].lower).any?
          entity.websites.create!(by_default: true, coordinate: @data[:merchant_website].lower)
        end
      end
    end

    # return a hash
    # https://entreprise.data.gouv.fr/api_doc/sirene
    def get_entity_on_sirene_v3(siret_number)
      entity_url = "https://entreprise.data.gouv.fr/api/sirene/v3/etablissements/#{siret_number}"
      call = RestClient.get entity_url
      response = JSON.parse(call.body).deep_symbolize_keys
      name = response[:etablissement][:unite_legale][:denomination]
      name ||= response[:etablissement][:unite_legale][:nom]
      { name: name,
        created_on: response[:etablissement][:date_creation],
        vat_number: response[:etablissement][:unite_legale][:numero_tva_intra],
        activity_code: response[:etablissement][:activite_principale],
        address: (response[:etablissement][:numero_voie].present? ? (response[:etablissement][:numero_voie] + ' ') : '') + response[:etablissement][:libelle_voie],
        postal_code: response[:etablissement][:code_postal],
        town: response[:etablissement][:libelle_commune],
        lat: response[:etablissement][:latitude],
        lon: response[:etablissement][:longitude]  }
    end

  end
end
