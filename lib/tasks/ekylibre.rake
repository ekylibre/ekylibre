# coding: utf-8
require 'ostruct'
STDOUT.sync = true
$stdout.sync = true

namespace :import do

  # $ rake import:isa[COMPANY,FILE]
  desc "Import IsaCompta file in a company"
  # task :isa, :company, :file, :needs => :environment do |t, args|
  task :isa, [:company, :file] => :environment do |t, args|
    if company = Company.find_by_code(args[:company])
      file = args[:file]
      if File.exist?(file)
        Exchanges.import(company, :isa_compta, file, :verbose=>true)
      else
        puts "Unfound file: #{file.inspect}"
      end
    else
      puts "Unfound company: #{args[:company].inspect}"
    end
  end



  # YOUNG FARMERS IMPORT


  YOUNG_CAST = Proc.new do |value, nature|
    casted = value.to_s.strip
    if nature == :boolean
      casted = casted.upcase == "X" ? true : false
    elsif nature == :yes_no
      casted = casted.upcase == "OUI" ? true : casted.upcase == "NON" ? false : nil
    elsif nature == :date
      casted = casted.blank? ? nil : Date.new(*casted.split(/[\/\s]+/)[0..2].map(&:to_i).reverse)
    elsif nature == :integer
      casted = casted.to_i
    elsif nature == :decimal
      casted = casted.to_d
    elsif nature == :phone
      casted = casted.blank? ? nil : casted.gsub(/\s+/, '').rjust(10, '0')
    elsif nature == :symbol
      casted = casted.blank? ? nil : casted.parameterize
    elsif nature.is_a? Hash
      casted = casted.blank? ? nil : nature[casted.upcase]
    else
      casted = casted.blank? ? nil : casted
    end
    casted
  end


  YOUNG_FARMER_FIELDS = {
    :yf_card => :boolean,
    :number => :string,
    :company => :string,
    :title => :string,
    :last_name => :string,
    :first_name => :string,
    :address => :string,
    :postal_code => :string,
    :city => :string,
    :district => :string,
    :small_region => :string,
    :mobile => :phone,
    :phone => :phone,
    :fax => :phone,
    :email => :string,
    :born_on => :date,
    :replacement_service => {"0" => 3391, "35" => 3392, "-35" => 3393},
    :first_production => :string,
    :second_production => :string,
    :third_production => :string,
    :exploiting => {"OUI" => 3394, "NON" => 3395, "EN COURS" => 3397},
    :sympathisant => :integer,
    :subscriber => :integer,
    :administration_counsil_mandate => :boolean,
    :canton_president_mandate => :boolean,
    :departemental_counsil_mandate => :boolean,
    :forum_installation_commission => :boolean,
    :viticulture_commission => :boolean,
    :elevage_commission => :boolean,
    :structures_commission => :boolean,
    :claf_member_mandate => :boolean,
    :evenementiel_commission => :boolean,
    :presse_commission => :boolean,
    :environnement_commission => :boolean,
    :diversification_commission => :boolean,
    :grandes_cultures_commission => :boolean,
    :fiscal_social_commission => :boolean,
    :jim_lands => {"X" => 3398, "RP" => 3399, "P" => 3400}
  }.freeze

  class YoungFarmer < Struct.new(*YOUNG_FARMER_FIELDS.keys)
    def initialize(*args)
      super(*args)
      for field, nature in YOUNG_FARMER_FIELDS
        send("#{field}=", YOUNG_CAST[send(field), nature])
      end
    end
  end


  YOUNG_INVOICE_FIELDS = {
    :id => :integer,
    :number => :string,
    :company => :string,
    :person_name => :string,
    :address => :string,
    :postal_code => :string,
    :city => :string,
    :remark => :string,
    :operation_nature => :string,
    :operation_family => :string,
    :invoiced_on => :date,
    :year => :integer,
    # Payment
    :paid_on => :date,
    :payment => :string,
    # Line 1
    :line_1_designation => :string,
    :line_1_product_id => :integer,
    :line_1_quantity => :integer,
    :line_1_unit_price => :decimal,
    :line_1_vat_rate => :decimal,
    :line_1_vat_amount => :decimal,
    # Line 2
    :line_2_designation => :string,
    :line_2_product_id => :integer,
    :line_2_quantity => :integer,
    :line_2_unit_price => :decimal,
    :line_2_vat_rate => :decimal,
    :line_2_vat_amount => :decimal,
    # Line 3
    :line_3_designation => :string,
    :line_3_product_id => :integer,
    :line_3_quantity => :integer,
    :line_3_unit_price => :decimal,
    :line_3_vat_rate => :decimal,
    :line_3_vat_amount => :decimal,
    # Totals
    :pretax_amount => :decimal,
    :amount => :decimal
  }

  class YoungInvoice < Struct.new(*YOUNG_INVOICE_FIELDS.keys)
    def initialize(*args)
      super(*args)
      for field, nature in YOUNG_INVOICE_FIELDS
        send("#{field}=", YOUNG_CAST[send(field), nature])
      end
    end
  end


  desc "Import JA 2014 file"
  task :ja2014, [:company, :subscriptions_file, :invoices_file] => :environment do |t, args|
    file = args[:subscriptions_file]
    unless company = Company.find_by_code(args[:company])
      raise "No company found: #{args[:company]}"
    end

    entities = {}

    ActiveRecord::Base.transaction do
      print "Subscriber: "
      CSV.foreach(file, :headers => true) do |row|
        farmer = YoungFarmer.new(*row.fields)
        # puts farmer.inspect
        unless nature = EntityNature.find_by_title(farmer.title)
          raise "Cannot find nature for #{farmer.title}"
        end
        person = company.entities.create!(:nature => nature, :active => true, :last_name => farmer.last_name, :first_name => farmer.first_name, :born_on => farmer.born_on, :category_id => 32)
        entities["#{farmer.last_name} #{farmer.first_name}"] = person
        # Check for district
        unless district = company.districts.find_by_name(farmer.district)
          district = company.districts.create!(:name => farmer.district)
        end
        # Check for area
        area_name = "#{farmer.postal_code} #{farmer.city}"
        unless area = company.areas.find_by_name(area_name)
          area = company.areas.create!(:name => area_name, :district => district, :country => "fr")
        end
        # Check for contact
        company.contacts.create!(:entity => person, :line_4 => farmer.address, :line_6 => "#{farmer.postal_code} #{farmer.city}", :mobile => farmer.mobile, :phone => farmer.phone, :fax => farmer.fax, :email => farmer.email)

        # Subscriptions
        if farmer.subscriber > 0
          company.subscriptions.create!(:entity => person, :nature_id => 82, :started_on => '2014-01-01', :stopped_on => '2015-02-28', :quantity => farmer.subscriber)
        end
        if farmer.sympathisant > 0
          company.subscriptions.create!(:entity => person, :nature_id => 83, :started_on => '2014-01-01', :stopped_on => '2015-02-28', :quantity => farmer.sympathisant)
        end

        # Productions
        for production in YOUNG_FARMER_FIELDS.keys.select{|k| k.to_s =~ /\_production\z/ }
          break unless farmer.send(production)
          name = "Production " + production.to_s.gsub(/\_production\z/, '').humanize
          unless field = company.custom_fields.find_by_name(name)
            field = company.custom_fields.create!(:name => name, :active => true, :nature => "choice")
          end
          choice_name = farmer.send(production).strip.humanize
          unless choice = field.choices.find_by_name(choice_name)
            choice = company.custom_field_choices.create!(:custom_field => field, :name => choice_name, :value => choice_name.parameterize)
          end
          company.custom_field_data.create!(:entity => person, :custom_field => field, :choice_value => choice)
        end
        
        # Custom fields
        # administration_counsil=false, district_president=false, departemental_counsil=false, claf_member=false
        for commission in YOUNG_FARMER_FIELDS.keys.select{|k| k.to_s =~ /\_mandate\z/ }
          name = commission.to_s.gsub(/\_mandate\z/, '').humanize
          unless field = company.custom_fields.find_by_name(name)
            field = company.custom_fields.create!(:name => name, :active => true, :nature => "boolean")
          end
          company.custom_field_data.create!(:entity => person, :custom_field => field, :boolean_value => !!farmer.send(commission))
        end

        # Commissions
        for commission in YOUNG_FARMER_FIELDS.keys.select{|k| k.to_s =~ /\_commission\z/ }
          name = "Commission " + commission.to_s.gsub(/\_commission\z/, '').humanize
          unless field = company.custom_fields.find_by_name(name)
            field = company.custom_fields.create!(:name => name, :active => true, :nature => "boolean")
          end
          company.custom_field_data.create!(:entity => person, :custom_field => field, :boolean_value => !!farmer.send(commission))
        end
        
        # Replacement_Service
        if farmer.replacement_service
          company.custom_field_data.create!(:entity => person, :custom_field_id => 367, :choice_value_id => farmer.replacement_service)
        end
        
        # Exploiting
        if farmer.exploiting
          company.custom_field_data.create!(:entity => person, :custom_field_id => 368, :choice_value_id => farmer.exploiting)
        end

        # TDJ2014
        if farmer.jim_lands
          company.custom_field_data.create!(:entity => person, :custom_field_id => 369, :choice_value_id => farmer.jim_lands)
        end

        farmer_company = nil
        if farmer.company
          unless farmer_company = entities[farmer.company]
            farmer_company = company.entities.create!(:nature_id => 1493, :active => true, :last_name => farmer.company, :category_id => 32)
            entities[farmer.company] = farmer_company
            # Add contact
            company.contacts.create!(:entity => farmer_company, :line_4 => farmer.address, :line_6 => "#{farmer.postal_code} #{farmer.city}", :mobile => farmer.mobile, :phone => farmer.phone, :fax => farmer.fax, :email => farmer.email)
          end
          # Add link
          company.entity_links.create!(:entity_1 => person, :entity_2 => farmer_company, :nature_id => 303)
        end

        print "."
        # break if rand(4).zero?
      end
      puts "!"

      print "Invoices: "
      file = args[:invoices_file]

      CSV.foreach(file, :headers => true) do |row|
        invoice = YoungInvoice.new(*row.fields)
        # puts invoice.inspect
        # Find client
        client = nil
        if invoice.company and !invoice.person_name
          clients = company.entities.where("TRIM(name) ILIKE ?", invoice.company.strip)
          if clients.count > 1
            raise "What? #{invoice.company}"
          elsif clients.count <= 0
            unless client = entities[invoice.company]
              client = company.entities.create!(:nature_id => 1493, :active => true, :last_name => invoice.company, :category_id => 32)
              entities[invoice.company] = client
              company.contacts.create!(:entity => client, :line_4 => invoice.address, :line_6 => "#{invoice.postal_code} #{invoice.city}")
            end
          else
            client = clients.first
          end
        elsif invoice.person_name
          clients = company.entities.where("COALESCE(last_name, '') || COALESCE(' ' || first_name, '') ILIKE ?", invoice.person_name)
          if clients.count > 1
            raise "What? #{invoice.person_name}"
          elsif clients.count <= 0
            unless client = entities[invoice.person_name]
              client = company.entities.create!(:nature_id => 1493, :active => true, :last_name => invoice.person_name, :category_id => 32)
              entities[invoice.company] = client
              company.contacts.create!(:entity => client, :line_4 => invoice.address, :line_6 => "#{invoice.postal_code} #{invoice.city}")
            end
          else
            client = clients.first
          end          
        else
          raise "What??? #{invoice.inspect}"
        end

        Timecop.travel(invoice.invoiced_on) do
          # Create sale
          sale = company.sales.create!(:nature_id => 40, :client => client)
          
          # Add lines
          for line_index in 1..3
            label = invoice.send("line_#{line_index}_designation")
            break unless label
            pid = invoice.send("line_#{line_index}_product_id")
            # Find or create price
            prices = company.prices.where(:product_id => pid, :tax_id => 184, :pretax_amount => invoice.send("line_#{line_index}_unit_price"), :category_id => 32)
            price =  prices.any? ? prices.first : company.prices.create!(:product_id => pid, :tax_id => 184, :pretax_amount => invoice.send("line_#{line_index}_unit_price"), :category_id => 32)
            # Add line
            sale.lines.create!(:label => label, :product_id => pid, :price => price, :quantity => invoice.send("line_#{line_index}_quantity"))
          end
          
          sale.save!

          # Invoice it
          sale.propose!
          sale.confirm!
          sale.invoice!

          # Fixes number
          Sale.update_all({:number => invoice.number}, {:id => sale.id})

          # Pay it or cancel it
          if invoice.payment
            type, bank, check_number = invoice.payment.split(" ")[0..2]
            if type == "ANN"
              sale.cancel
            else
              mode_id = nil
              if type == "CHQ"
                mode_id = 108
              elsif type == "VRT"
                mode_id = 109
              else
                raise "What payment type ? #{type.inspect}"
              end
              on = invoice.paid_on || sale.invoiced_on
              Timecop.travel(on) do
                payment = company.incoming_payments.create!(:mode_id => mode_id, :amount => sale.amount, :bank => bank, :check_number => check_number, :paid_on => on, :to_bank_on => on, :payer => client)
                unless payment.pay(sale)
                  raise payment.errors.inspect
                end
              end
            end
          end
          
        end
        # Finished!
        print "."
      end

      puts "!"

      # raise "Stop"
    end
    
  end

end
