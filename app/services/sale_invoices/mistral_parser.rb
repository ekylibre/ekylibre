# frozen_string_literal: true

module SaleInvoices
  class MistralParser

    # @data : document structure must respect db/nomenclatures/ai_context.yml
    # items = [{}, {}]
    # client = {}
    # invoice = {}
    def initialize(vendor, document_id)
      @document = Document.find(document_id)
      @data = @document.metadata[vendor.to_s].deep_symbolize_keys.to_struct
      @sirene = find_entity_on_sirene_v3 if %w[fr france].include? @data.client[:country].downcase
    end

    # return nil or an id of pruchase created
    def parse_and_create_invoice
      client = find_client || create_client
      unless client
        puts "No client found and error on created".inspect.red
        return nil
      end
      if @data.invoice[:invoiced_on].present? && @data.invoice[:invoiced_on].size < 10
        old_date = @data.invoice[:invoiced_on].split('/')
        year = "20" + old_date[2]
        invoiced_at = Date.parse("#{old_date[0]}/#{old_date[1]}/#{year}")
      elsif @data.invoice[:invoiced_on].present?
        invoiced_at = Date.parse(@data.invoice[:invoiced_on]).to_time
      end

      unless invoiced_at
        puts "Purchase date not present".inspect.red
        return nil
      end
      sale = Sale.new(
        confirmed_at: invoiced_at,
        invoiced_at: invoiced_at,
        reference_number: @data.invoice[:number],
        currency: @data.invoice[:currency],
        client: client,
        nature: SaleNature.actives.first,
        description: "#{client.name} | #{invoiced_at.to_date.to_s} | #{@data.invoice[:number]}"
      )
      clean_lines = build_lines(invoiced_at, client)
      if sale && clean_lines.any?
        clean_lines.each do |item|
          sale.items.new(item)
        end
      end
      if sale.save!
        sale.attachments.create!(document: @document)
        sale.id
      else
        puts sale.errors.full_messages.inspect.red
        nil
      end
    end

    # build lines items
    def build_lines(invoiced_at, client)
      items = []
      if @data.items.any?
        @data.items.each do |line|
          puts line.inspect.yellow
          # :name=>nil,
          # :quantity=>nil,
          # :unit_amount=>19.99,
          # :unit_pretax_amount=>19.99,
          # :amount => ,
          # :pretax_amount=>19.99,
          # :tax_amount=>nil,
          # :tax_rate=>nil,
          # :nature=>nil
          next if line[:unit_pretax_amount]&.to_d == 0.0 && line[:pretax_amount]&.to_d == 0.0

          if line[:tax_rate].present?
            vat_percentage = line[:tax_rate].to_d
          else
            vat_percentage = 0.0
          end
          infos = guess_line_info(product_code: line[:number], description: line[:name], vat_percentage: vat_percentage, supplier: client, category: line[:nature])
          next unless infos

          items << {  annotation: line[:name],
                      conditioning_quantity: (line[:quantity]&.to_d || 1.0),
                      conditioning_unit_id: infos[:unit].id,
                      tax_id: infos[:tax].id,
                      amount: nil,
                      pretax_amount: nil,
                      unit_pretax_amount: (line[:unit_pretax_amount]&.to_d || line[:pretax_amount]&.to_d),
                      variant_id: infos[:variant].id,
                      fixed: false,
                      compute_from: :unit_pretax_amount }
        end
      end
      items
    end

    def guess_line_info(product_code: nil, description:, vat_percentage:, supplier:, category:)
      puts description.inspect.yellow
      puts supplier.inspect.yellow
      puts category.inspect.yellow
      variant = guess_variant(description, supplier, category)
      if variant.present?
        infos = {
          variant: variant,
          tax: guess_tax(vat_percentage, supplier, variant),
          unit: guess_unit(variant)
        }
      else
        nil
      end
    end

    def guess_variant(title, supplier, category)
      # 1 / find variants from tags
      tag = ProductNatureVariantTag.where(name: title.strip, entity_id: supplier.id)&.first
      tags = ProductNatureVariantTag.where("similarity(unaccent(name), unaccent(?)) >= 0.9", title.strip)
      # 2 / find variants from variant name
      similar_variants_05 = ProductNatureVariant.where("similarity(unaccent(name), unaccent(?)) >= 0.5", title.strip)
      similar_variants_02 = ProductNatureVariant.where("similarity(unaccent(name), unaccent(?)) >= 0.2", title.strip)
      # similar_categories = ProductNatureCategory.where("similarity(unaccent(name), unaccent(?)) >= 0.5", category.strip) if category.present?
      article = Duke::Skill::DukeArticle.new(user_input: title, supplier: supplier)
      products = Duke::DukeMatchingArray.new
      article.extract_user_specifics(duke_json: { supplier_article: products })
      if tag.present?
        variant = tag.variant
      elsif tags.any?
        variant = tags.first.variant
      elsif similar_variants_05.present?
        variant = similar_variants_05.first
      elsif similar_variants_02.present?
        variant = similar_variants_02.first
      elsif (product=article.supplier_article.max).present?
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
      # add infos in product_nature_variant_tag model
      unless tag
        variant.article_tags.create!(entity: supplier, name: title.strip)
      end
      variant
    end

    def guess_unit(variant)
      Unit.import_from_lexicon(:unity)
    end

    def guess_tax(percentage, supplier, variant)
      if percentage.present?
        tax = Tax.where(active: true, amount: ((percentage * 0.95)..(percentage * 1.05))).last
      elsif variant.present?
        tax = if (sale_items=SaleItem.where(variant: variant)).any?
                sale_items.order(id: :desc).first.tax
              elsif MasterVariantCategory.find_by_reference_name(variant.category.reference_name).present?
                Tax.where(amount: MasterVariantCategory.find_by_reference_name(variant.category.reference_name).default_vat_rate).last
              end
      else
        tax = Tax.where(active: true, amount: 0.00).last
      end
      tax
    end

    # find an Entity
    def find_client
      # NAME
      if @data.client[:name].present?
        similar_entity = Entity.where("similarity(unaccent(full_name), unaccent(?)) >= 0.5", @data.client[:name].strip)
        ilike_entity = Entity.where('full_name ILIKE ?', @data.client[:name].strip)
      end
      entity = similar_entity.first || ilike_entity.first

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
    def create_client
      if @data.client[:name].present?
        entity = Entity.new
        entity.nature = :organization
        entity.active = true
        entity.client = true
        entity.last_name = @data.client[:name].strip
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
      if entity.present?
        # create mail address from metadata
        if @data.client[:address].present? && @data.client[:postal_code].present? && @data.client[:town].present?
          line_6 = @data.client[:postal_code] + ' ' + @data.client[:town]
          line_4 = @data.client[:address]
          attrs = { by_default: true, mail_line_6: line_6, mail_country: 'fr' }
          attrs[:mail_line_4] = line_4 if line_4.present?
        # create mail address from entity siret and SIRENE v3 API
        elsif @sirene.present?
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
      if @data.client[:registration_number].present?
        ident = @data.client[:registration_number].delete(" ").gsub(/[^0-9]/, '')
        if ident.size == 14
          siret_number = ident
        elsif ident.size == 9
          siren_number = ident
        end
      end
      if siret_number.present?
        CompanyInformationsService.call(siret: siret_number)
      elsif siren_number.present?
        CompanyInformationsService.call(siren: siren_number)
      elsif @data.client[:name].present? && @data.client[:postal_code].present?
        CompanyInformationsService.call(name: @data.client[:name].strip, postal_code: @data.client[:postal_code].strip)
      elsif @data.client[:name].present?
        CompanyInformationsService.call(name: @data.client[:name].strip)
      else
        nil
      end
    end

  end
end
