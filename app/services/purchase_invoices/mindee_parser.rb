# frozen_string_literal: true

module PurchaseInvoices
  class MindeeParser

    VENDOR = 'mindee'

    def initialize(document_id)
      @document = Document.find(document_id)
      @data = JSON.parse(@document.klippa_metadata).deep_symbolize_keys.to_struct
      @sirene = find_entity_on_sirene_v3 if @data.locale[:language] == 'fr'
    end

    # return nil or an id of pruchase created
    def parse_and_create_invoice
      supplier = find_supplier || create_supplier
      unless supplier
        puts "No supplier found and error on created".inspect.red
        return nil
      end
      invoiced_at = Date.parse(@data.date[:value]).to_time if @data.date.present?
      unless invoiced_at
        puts "Purchase date not present".inspect.red
        return nil
      end
      purchase = PurchaseInvoice.new(
        planned_at: invoiced_at,
        invoiced_at: invoiced_at,
        reference_number: @data.invoice_number[:value],
        currency: @data.locale[:currency],
        supplier: supplier,
        nature: PurchaseNature.actives.first,
        description: "#{supplier.name} | #{invoiced_at.to_date.to_s} | #{@data.invoice_number[:value]}"
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
      if @data.line_items.any?
        @data.line_items.each do |line|
          puts line.inspect.yellow
          # :product_code=>nil,
          # :quantity=>nil,
          # :unit_price=>19.99,
          # :total_amount=>19.99,
          # :tax_amount=>nil,
          # :tax_rate=>nil,
          # :description=>"Vos abonnements, options et services du 01/10/2023 au 31/10/2023 - Abonnement Forfait Mobile Free Pro du 01/10/2023 au 31/10/2023",
          # :page_id=>nil
          if line[:tax_rate].nil? || (detect_global_vat_rate && line[:tax_rate]&.to_d == 0.0)
            vat_percentage = detect_global_vat_rate
          elsif line[:tax_rate].present?
            vat_percentage = line[:tax_rate].to_d
          else
            vat_percentage = 0.0
          end
          puts vat_percentage.inspect.red
          infos = guess_line_info(product_code: line[:product_code], description: line[:description], vat_percentage: vat_percentage, supplier: supplier)
          items << { role: 'merchandise',
                      annotation: line[:description],
                      conditioning_quantity: (line[:quantity]&.to_d || 1.0),
                      conditioning_unit_id: infos[:unit].id,
                      tax_id: infos[:tax].id,
                      unit_pretax_amount: (line[:unit_price]&.to_d || line[:total_amount]&.to_d),
                      variant_id: infos[:variant].id,
                      fixed: false }
        end
      end
      items
    end

    def guess_line_info(product_code: nil, description:, vat_percentage:, supplier:)
      puts vat_percentage.inspect.yellow
      variant = guess_variant(description, supplier)
      infos = {
        variant: variant,
        tax: guess_tax(vat_percentage, supplier),
        unit: guess_unit(variant)
      }
    end

    def detect_global_vat_rate
      rate = nil
      if @data.taxes.present? && @data.taxes.count == 1
        @data.taxes.first[:rate]
      elsif @data.total_tax.present? && @data.total_net.present?
        rate = ((@data.total_tax[:value].to_d / @data.total_net[:value].to_d) * 100)
      else
        rate = 0.0
      end
      puts rate.inspect.green
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
      puts variant.inspect.green
      variant
    end

    def guess_unit(variant)
      Unit.import_from_lexicon(:unity)
    end

    def guess_tax(percentage, supplier)
      tax = Tax.where(active: true, amount: ((percentage * 0.95)..(percentage * 1.05))).first
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
      entity = Entity.where('full_name ILIKE ?', @data.supplier_name[:value].strip).first if @data.supplier_name.present?

      # VAT NUMBER
      entity ||= Entity.find_by(vat_number: @sirene[:vat_number]) if @sirene && @sirene[:vat_number].present?

      # SIRET
      entity ||= Entity.find_by(siret_number: @sirene[:siret_number]) if @sirene && @sirene[:siret_number].present?

      # ZIPCODE & CITY
      line_6 = @sirene[:city] if @sirene && @sirene[:city].present?
      ea = EntityAddress.find_by(canal: :mail, mail_line_6: line_6, mail_country: 'fr') if line_6.present?
      entity ||= Entity.find_by(id: ea.entity_id) if ea

      if entity.present?
        # autocomplete informations if missing
        if @sirene.present?
          entity.vat_number ||= @sirene[:vat_number] if @sirene[:vat_number].present?
          entity.activity_code ||= @sirene[:activity_code] if @sirene[:activity_code].present?
          entity.born_at ||= @sirene[:company_creation_date].to_time if @sirene[:company_creation_date].present?
        end
        entity.save!
        create_default_mail_address(entity)
        entity
      else
        nil
      end
    end

    # create an Entity
    def create_supplier
      if @data.supplier_name.present?
        entity = Entity.new
        entity.nature = :organization
        entity.active = true
        entity.supplier = true
        entity.last_name = @data.supplier_name[:value].strip
        # complete informations with SIRENE v3 API
        if @sirene.present?
          entity.siret_number ||= @sirene[:siret_number] if @sirene[:siret_number].present?
          entity.vat_number ||= @sirene[:vat_number] if @sirene[:vat_number].present?
          entity.activity_code ||= @sirene[:activity_code] if @sirene[:activity_code].present?
          entity.born_at ||= @sirene[:company_creation_date].to_time if @sirene[:company_creation_date].present?
        end
        # end SIRENE v3 API
        entity.save!
        create_default_mail_address(entity)
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
          attrs = { by_default: true, mail_line_6: line_6, mail_country: 'fr' }
          attrs[:mail_line_4] = line_4 if line_4.present?
        # create mail address from entity siret and SIRENE v3 API
        elsif entity && @sirene.present?
          line_6 = @sirene[:city]
          line_4 = @sirene[:address]
          attrs = { by_default: true, mail_line_6: line_6, mail_country: 'fr' }
          attrs[:mail_line_4] = line_4 if line_4.present?
        end
        if line_6.present? && !entity.mails.where('mail_line_6 ILIKE ?', line_6).where(mail_country: 'fr').any?
          entity.mails.create!(attrs)
        end
      else
        nil
      end
    end

    # return a hash
    # {:company_name=>"FREE PRO",
    #  :address=>"3 RUE PAUL BRUTUS",
    #  :city=>"13015 MARSEILLE 15",
    #  :company_creation_date=>Tue, 04 Sep 2001,
    #  :activity_code=>"61.10Z",
    #  :vat_number=>nil,
    #  :lng=>5.363258,
    #  :lat=>43.324017,
    #  :siret_number=>"43909965600142"}
    def find_entity_on_sirene_v3
      siret_number = nil
      siren_number = nil
      @data.supplier_company_registrations.each do |supplier_ident|
        if supplier_ident[:type] == "SIRET"
          siret_number = supplier_ident[:value]
        elsif supplier_ident[:type] == "SIREN"
          siren_number = supplier_ident[:value]
        end
      end
      if siret_number.present?
        CompanyInformationsService.call(siret: siret_number)
      elsif siren_number.present?
        CompanyInformationsService.call(siren: siren_number)
      else
        nil
      end
    end

  end
end
