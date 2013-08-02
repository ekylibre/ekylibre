# -*- coding: utf-8 -*-
module Ekylibre
  DEMOS = [:general_ledger, :buildings, :animals, :land_parcels, :sales]


  class FixtureCountExceeded < StandardError
  end

  class Fixturize
    def initialize(max)
      @count = 0
      @max = max
    end

    def check_point
      @count += 1
      print "."
      raise FixtureCountExceeded.new if @count >= @max
    end
  end

  def self.fixturize(name, options = {}, &block)
    STDOUT.sync = true
    max = ENV["max"].to_i
    max = 1_000_000 if max.zero?
    f = Fixturize.new(max)
    start = Time.now
    ActiveRecord::Base.transaction do
      print "#{name.to_s.rjust(32)}: "
      begin
        yield(f)
      rescue FixtureCountExceeded => e
        print "! "
      end
    end
    puts "#{(Time.now - start).round(2).to_s.rjust(8)}s"
  end

end

require 'ostruct'
require 'pathname'

namespace :db do
  task :demo => :demo
end

desc "Build demo data"
namespace :demo do
  for demo in Ekylibre::DEMOS
    require Pathname.new(__FILE__).dirname.join("demo", demo.to_s).to_s
  end
end

desc "Create demo data -- also available " + Ekylibre::DEMOS.collect{|c| "demo:#{c}"}.join(", ")
task :demo => :environment do
  # Ekylibre::fixturize(:demo) do |w|
  ActiveRecord::Base.transaction do
    for demo in Ekylibre::DEMOS
      Rake::Task["demo:#{demo}"].invoke
    end
  end
end


# TODO REMOVE THAT FUCKING STUFF BELOW


  desc "Build demo data"
  task :old_demo => :environment do
    start = Time.now
    STDOUT.sync = true
    max = ENV["max"].to_i
    max = 1_000_000 if max.zero?
    puts "Started: "
    ActiveRecord::Base.transaction do


      #############################################################################
      # import Coop Order to make automatic purchase
      # @TODO finish with two level (purchases and purchases_lines)
      #
      # set the coop
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] IncomingDeliveries - Charentes Alliance Coop Order (Appro) 2013: "

      price_listing = ProductPriceListing.find_by_code("STD")

      # # create product_nature for organic matters and others usefull for coop
      # herbicide = ProductNature.import_from_nomenclature(:herbicide).default_variant
      # fungicide = ProductNature.import_from_nomenclature(:fungicide).default_variant
      # insecticide = ProductNature.import_from_nomenclature(:insecticide).default_variant
      # # @TODO = anti-limace
      # chemical_fertilizer = ProductNature.import_from_nomenclature(:chemical_fertilizer).default_variant
      # seed = ProductNature.import_from_nomenclature(:seed).default_variant
      # feed = ProductNature.import_from_nomenclature(:feed).default_variant
      # animal_medicine = ProductNature.import_from_nomenclature(:animal_medicine).default_variant
      # spread_renting = ProductNature.import_from_nomenclature(:spread_renting).default_variant
      # mineral_cleaner = ProductNature.import_from_nomenclature(:mineral_cleaner).default_variant

      appro_price_template_tax = Tax.find_by_amount(5.5)

      suppliers = Entity.where(:of_company => false, :supplier => true).reorder(:supplier_account_id, :last_name) # .where(" IS NOT NULL")
      coop = suppliers.offset((suppliers.count/2).floor).first

      # add Coop incoming deliveries

      # status to map
      status = {
        "Liquidé" => :order,
        "A livrer" => :estimate,
        "Supprimé" => :aborted
      }

      pnature = {
        "Maïs classe a" => "seed",
        "Graminées fourragères" => "seed",
        "Légumineuses fourragères" => "seed",
        "Divers" => "seed",
        "Blé tendre" => "seed",
        "Blé dur" => "seed",
        "Orge hiver escourgeon" => "seed",
        "Couverts environnementaux enherbeme" => "seed",

        "Engrais" => "chemical_fertilizer",

        "Fongicides céréales" => "fungicide",
        "Fongicides colza" => "fungicide",
        "Herbicides maïs" => "herbicide",
        "Herbicides totaux" => "herbicide",
        "Adjuvants" => "herbicide",
        "Herbicides autres" => "herbicide",
        "Herbicides céréales et fouragères" => "herbicide",

        "Céréales"  => "feed",
        "Chevaux" => "feed",
        "Compléments nutritionnels" => "feed",
        "Minéraux sel blocs" => "feed",

        "Anti-limaces" => "insecticide",

        "Location semoir" => "spread_renting",

        "Nettoyants" => "mineral_cleaner",

        "Films plastiques" => "small_equipment",
        "Recyclage" => "small_equipment",
        "Ficelles" => "small_equipment"
      }

      file = Rails.root.join("test", "fixtures", "files", "coop_appro.csv")
      CSV.foreach(file, :encoding => "UTF-8", :col_sep => ";", :headers => true) do |row|
        r = OpenStruct.new(:order_number => row[0],
                           :ordered_on => Date.civil(*row[1].to_s.split(/\//).reverse.map(&:to_i)),
                           # :product_nature_category => ProductNatureCategory.find_by_name(row[2]) || ProductNatureCategory.create!(:catalog_name => row[2], :name => row[2], :published => true ) ,
                           :product_nature_name => (pnature[row[3]] || "small_equipment"),
                           :matter_name => row[4],
                           :quantity => (row[5].blank? ? nil : row[5].to_d),
                           :product_deliver_quantity => (row[6].blank? ? nil : row[6].to_d),
                           :product_unit_price => (row[7].blank? ? nil : row[7].to_d),
                           :order_status => (status[row[8]] || :draft)
                           )
        # create an incoming deliveries if not exist and status = 2
        if r.order_status == :order
          order = IncomingDelivery.find_by_reference_number(r.order_number)
          order ||= IncomingDelivery.create!(:reference_number => r.order_number, :received_at => r.ordered_on, :sender_id => coop.id, :address_id => "1")
          # find a product_nature by mapping current sub_family of coop file
          product_nature = ProductNature.find_by_nomen(r.product_nature_name)
          product_nature ||= ProductNature.import_from_nomenclature(r.product_nature_name)
          # find a product_nature_variant by mapping current article of coop file
          product_nature_variant = ProductNatureVariant.find_by_name_and_nature_id(r.matter_name,product_nature.id )
          product_nature_variant ||= product_nature.variants.create!(:name => r.matter_name, :active => true, :unit_name => "unit")
          # find a price from current supplier for a consider variant
          product_nature_variant_price = ProductPrice.find_by_supplier_id_and_variant_id_and_pretax_amount(coop.id, product_nature_variant.id, r.product_unit_price)
          product_nature_variant_price ||= ProductPrice.create!(:pretax_amount => r.product_unit_price,
                                                                                 :currency => "EUR",
                                                                                 :supplier_id => coop.id,
                                                                                 :tax_id => appro_price_template_tax.id,
                                                                                 :amount => appro_price_template_tax.amount_of(r.product_unit_price),
                                                                                 :variant_id => product_nature_variant.id
                                                                                 )

          product_model = product_nature.matching_model
          incoming_item = Product.find_by_variant_id_and_created_at(product_nature_variant.id, r.ordered_on)
          incoming_item ||= product_model.create!(:owner_id => Entity.of_company.id, :identification_number => r.order_number, :variant_id => product_nature_variant.id, :born_at => r.ordered_on, :created_at => r.ordered_on)
          # incoming_item.indicator_data.create!(:indicator => product_nature_variant.purchase_indicator, :value => r.quantity,
          # :measure_unit => product_nature_variant.purchase_indicator_unit,
          # :measured_at => Time.now
          # )
          incoming_item.is_measured!(:population, r.quantity.in_unity, :at => Time.now)
          if product_nature.present? and incoming_item.present?
            order.items.create!(:product_id => incoming_item.id, :quantity => r.product_deliver_quantity)
          end
        end
        # purchase   = Purchase.find_by_reference_number(r.order_number)
        # purchase ||= Purchase.create!(:state => r.order_status, :currency => "EUR", :nature_id => purchase_nature.id, :reference_number => r.order_number, :supplier_id => coop.id, :planned_on => r.ordered_on, :created_on => r.ordered_on)
        # tax_price_nature_appro = Tax.find_by_amount(19.6)
        # # create a product_nature if not exist
        # product_nature   = ProductNature.find_by_name(r.product_nature_name)
        # product_nature ||= ProductNature.create!(:stock_account_id => stock_account_nature_coop.id, :charge_account_id => charge_account_nature_coop.id, :name => r.product_nature_name, :saleable => false, :purchasable => true, :active => true, :storable => true, :variety => "building", :unit => "unity", :category_id => r.product_nature_category.id)
        # # create a product (Matter) if not exist
        # product   = Matter.find_by_name(r.matter_name)
        # product ||= Matter.create!(:name => r.matter_name, :identification_number => r.matter_name, :work_number => r.matter_name, :born_at => Time.now, :nature_id => product_nature.id, :owner_id => Entity.of_company.id, :number => r.matter_name) #
        # # create a product_price_template if not exist
        # product_price   = ProductPriceTemplate.find_by_product_nature_id_and_supplier_id_and_assignment_pretax_amount(product_nature.id, coop.id, r.product_unit_price)
        # product_price ||= ProductPriceTemplate.create!(:currency => "EUR", :assignment_pretax_amount => r.product_unit_price, :product_nature_id => product_nature.id, :tax_id => tax_price_nature_appro.id, :supplier_id => coop.id)
        # # create a purchase_item if not exist
        # # purchase_item   = PurchaseItem.find_by_product_id_and_purchase_id_and_price_id(product.id, purchase.id, product_price.id)
        # # purchase_item ||= PurchaseItem.create!(:quantity => r.quantity, :unit_id => unit_u.id, :price_id => product_price.id, :product_id => product.id, :purchase_id => purchase.id)
        # # puts "Default PPT: " + ProductPriceTemplate.by_default.class.name # (coop.id, product.nature_id).inspect
        # purchase.items.create!(:quantity => r.quantity, :product_id => product.id) unless r.quantity.zero?
        # # create an incoming_delivery if status => 2

        # create an incoming_delivery_item if status => 2


        print "."
      end

      puts "!"




      # #############################################################################
      # # import Coop Deliveries to make automatic sales
      # # @TODO finish with two level (sales and sales_lines)
      # @TODO make some correction for act_as_numbered
      # # set the coop
      # print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] OutgoingDelivery - Charentes Alliance Coop Delivery (Apport) 2013: "
      # clients = Entity.where(:of_company => false).reorder(:client_account_id, :last_name) # .where(" IS NOT NULL")
      # coop = clients.offset((clients.count/2).floor).first
      # unit_u = Unit.get(:u)
      # # add a Coop sale_nature
      # sale_nature   = SaleNature.actives.first
      # sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => "EUR", :active => true)
      # # Asset Code
      # sale_account_nature_coop = Account.find_by_number("701")
      # stock_account_nature_coop = Account.find_by_number("321")

      # file = Rails.root.join("test", "fixtures", "files", "coop-apport.csv")
      # CSV.foreach(file, :encoding => "UTF-8", :col_sep => ";", :headers => false, :quote_char => "'") do |row|
      #   r = OpenStruct.new(:delivery_number => row[0],
      #                      :delivered_on => Date.civil(*row[1].to_s.split(/\//).reverse.map(&:to_i)),
      #                      :delivery_place => row[2],
      #                      :product_nature_name => row[3],
      #                      :product_net_weight => row[4].to_d,
      #                      :product_standard_weight => row[5].to_d,
      #                      :product_humidity => row[6].to_d,
      #                      :product_impurity => row[7].to_d,
      #                      :product_specific_weight => row[8].to_d,
      #                      :product_proteins => row[9].to_d,
      #                      :product_cal => row[10].to_d,
      #                      :product_mad => row[11].to_d,
      #                      :product_grade => row[12].to_d,
      #                      :product_expansion => row[13].to_d
      #                      )
      #   # create a purchase if not exist
      #   sale   = Sale.find_by_reference_number(r.delivery_number)
      #   sale ||= Sale.create!(:state => r.order_status, :currency => "EUR", :nature_id => purchase_nature.id, :reference_number => r.order_number, :supplier_id => coop.id, :planned_on => r.ordered_on, :created_on => r.ordered_on)
      #   tax_price_nature_appro = Tax.find_by_amount(19.6)
      #   # create a product_nature if not exist
      #   product_nature   = ProductNature.find_by_name(r.product_nature_name)
      #   product_nature ||= ProductNature.create!(:stock_account_id => stock_account_nature_coop.id, :charge_account_id => charge_account_nature_coop.id, :name => r.product_nature_name, :number => r.product_nature_name,  :saleable => false, :purchasable => true, :active => true, :storable => true, :variety_id => b.id, :unit_id => unit_u.id, :category_id => ProductNatureCategory.by_default.id)
      #   # create a product (Matter) if not exist
      #   product   = Matter.find_by_name(r.matter_name)
      #   product ||= Matter.create!(:name => r.matter_name, :identification_number => r.matter_name, :work_number => r.matter_name, :born_at => Time.now, :nature_id => product_nature.id, :owner_id => Entity.of_company.id, :number => r.matter_name) #
      #   # create a product_price_template if not exist
      #   product_price   = ProductPriceTemplate.find_by_product_nature_id_and_supplier_id_and_assignment_pretax_amount(product_nature.id, coop.id, r.product_unit_price)
      #   product_price ||= ProductPriceTemplate.create!(:currency => "EUR", :assignment_pretax_amount => r.product_unit_price, :product_nature_id => product_nature.id, :tax_id => tax_price_nature_appro.id, :supplier_id => coop.id)
      #   # create a purchase_item if not exist
      #   # purchase_item   = PurchaseItem.find_by_product_id_and_purchase_id_and_price_id(product.id, purchase.id, product_price.id)
      #   # purchase_item ||= PurchaseItem.create!(:quantity => r.quantity, :unit_id => unit_u.id, :price_id => product_price.id, :product_id => product.id, :purchase_id => purchase.id)
      #   purchase.items.create!(:quantity => r.quantity, :product_id => product.id)
      #   # create an incoming_delivery if status => 2

      #   # create an incoming_delivery_item if status => 2


      #   print "."
      # end
      # puts "!"

      #############################################################################
      # import Milk result to make automatic quality indicators
      # @TODO
      #
      # set the lab
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Indicators - LILCO Milk analysis 2013: "
      # set the product if not exist
      # @TODO = appeller la méthode des comptes comme dans la nomenclature accounts
      # variety_milk = ProductVariety.find_by_code("normande")
      # add a product_nature
      product_nature_variant = ProductNature.import_from_nomenclature(:milk).default_variant

      # create a generic product to link analysis_indicator
      product   = OrganicMatter.find_by_name("lait_vache")
      product ||= OrganicMatter.create!(:name => "lait_vache", :identification_number => "MILK_FR_2010-2013", :work_number => "lait_2013", :born_at => Time.now, :variant_id => product_nature_variant.id, :owner_id => Entity.of_company.id) #

      trans_inhib = {
        "NEG" => "negative",
        "POS" => "positive"
      }

      file = Rails.root.join("test", "fixtures", "files", "HistoIP_V.csv")
      CSV.foreach(file, :encoding => "CP1252", :col_sep => "\t", :headers => true) do |row|
        analysis_on = Date.civil(row[0].to_i, row[1].to_i, 1)
        r = OpenStruct.new(:analysis_year => row[0],
                           :analysis_month => row[1],
                           :analysis_order => row[2],
                           :analysis_quality_indicator_germes => (row[3].blank? ? 0 : row[3].to_i),
                           :analysis_quality_indicator_inhib => (row[4].blank? ? "negative" : trans_inhib[row[4]]),
                           :analysis_quality_indicator_mg => (row[5].blank? ? 0 : (row[5].to_d)/100),
                           :analysis_quality_indicator_mp => (row[6].blank? ? 0 : (row[6].to_d)/100),
                           :analysis_quality_indicator_cellules => (row[7].blank? ? 0 : row[7].to_i),
                           :analysis_quality_indicator_buty => (row[8].blank? ? 0 : row[8].to_i),
                           :analysis_quality_indicator_cryo => (row[9].blank? ? 0.00 : row[9].to_d),
                           :analysis_quality_indicator_lipo => (row[10].blank? ? 0.00 : row[10].to_d),
                           :analysis_quality_indicator_igg => (row[11].blank? ? 0.00 : row[11].to_d),
                           :analysis_quality_indicator_uree => (row[12].blank? ? 0 : row[12].to_i),
                           :analysis_quality_indicator_salmon => row[13],
                           :analysis_quality_indicator_listeria => row[14],
                           :analysis_quality_indicator_staph => row[15],
                           :analysis_quality_indicator_coli => row[16],
                           :analysis_quality_indicator_pseudo => row[17],
                           :analysis_quality_indicator_ecoli => row[18]
                          )

        # create an indicator for each line of analysis (based onn milk analysis indicator in XML nomenclature)
        # product.indicator_data.create!(:indicator => "total_bacteria_concentration", :value => r.analysis_quality_indicator_germes , :measure_unit => "thousands_per_milliliter" , :measured_at => analysis_on )
        # product.indicator_data.create!(:indicator => "inhibitors_presence", :value => r.analysis_quality_indicator_inhib , :measured_at => analysis_on )
        # product.indicator_data.create!(:indicator => "fat_matters_concentration", :value => r.analysis_quality_indicator_mg , :measure_unit => "gram_per_liter", :measured_at => analysis_on )
        # product.indicator_data.create!(:indicator => "protein_matters_concentration", :value => r.analysis_quality_indicator_mp , :measure_unit => "gram_per_liter", :measured_at => analysis_on )
        # product.indicator_data.create!(:indicator => "cells_concentration", :value => r.analysis_quality_indicator_cellules , :measure_unit => "thousands_per_milliliter", :measured_at => analysis_on )
        # product.indicator_data.create!(:indicator => "clostridial_spores_concentration", :value => r.analysis_quality_indicator_buty , :measure_unit => "unities_per_liter", :measured_at => analysis_on )
        # product.indicator_data.create!(:indicator => "freezing_point_temperature", :value => r.analysis_quality_indicator_cryo , :measure_unit => "celsius", :measured_at => analysis_on )
        # product.indicator_data.create!(:indicator => "lipolysis", :value => r.analysis_quality_indicator_lipo , :measure_unit => "thousands_per_hectogram", :measured_at => analysis_on )
        # product.indicator_data.create!(:indicator => "immunoglobulins_concentration", :value => r.analysis_quality_indicator_igg , :measure_unit => "unities_per_liter", :measured_at => analysis_on )
        # product.indicator_data.create!(:indicator => "urea_concentration", :value => r.analysis_quality_indicator_uree , :measure_unit => "milligram_per_liter", :measured_at => analysis_on )
#
        product.is_measured!(:total_bacteria_concentration, r.analysis_quality_indicator_germes.in_thousand_per_milliliter, :at => analysis_on)
        product.is_measured!(:inhibitors_presence, r.analysis_quality_indicator_inhib, :at => analysis_on)
        product.is_measured!(:fat_matters_concentration, r.analysis_quality_indicator_mg.in_gram_per_liter, :at => analysis_on)
        product.is_measured!(:protein_matters_concentration, r.analysis_quality_indicator_mp.in_gram_per_liter, :at => analysis_on)
        product.is_measured!(:cells_concentration, r.analysis_quality_indicator_cellules.in_thousand_per_milliliter, :at => analysis_on)
        product.is_measured!(:clostridial_spores_concentration, r.analysis_quality_indicator_buty.in_unity_per_liter, :at => analysis_on)
        product.is_measured!(:freezing_point_temperature, r.analysis_quality_indicator_cryo.in_celsius, :at => analysis_on)
        product.is_measured!(:lipolysis, r.analysis_quality_indicator_lipo.in_thousand_per_hectogram, :at => analysis_on)
        product.is_measured!(:immunoglobulins_concentration, r.analysis_quality_indicator_igg.in_unity_per_liter, :at => analysis_on)
        product.is_measured!(:urea_concentration, r.analysis_quality_indicator_uree.in_milligram_per_liter, :at => analysis_on)

        print "."
      end
      puts "!"

      #############################################################################
      # import some base activities from CSV
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Activities: "


      # attributes to map family
      families = {
        "CEREA" => :vegetal,
        "COPLI" => :vegetal,
        "CUFOU" => :vegetal,
        "ANIMX" => :animal,
        "XXXXX" => :none,
        "NINCO" => :none
      }
      # attributes to map nature
      natures = {
        "PRINC" => :main,
        "AUX" => :auxiliary,
        "" => :none
      }
      # Load file
      file = Rails.root.join("test", "fixtures", "files", "activities_ref_demo_2.csv")
      CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
        r = OpenStruct.new(:description => row[0],
                           :name => row[1].downcase.capitalize,
                           :family => (families[row[2]] || :none).to_s,
                           :product_nature_nomen => row[3].blank? ? nil :row[3].to_sym,
                           :nature => (natures[row[4]] || :none).to_s,
                           :campaign_name => row[5].blank? ? nil : row[5].to_s,
                           :work_number_land_parcel_storage => row[6].blank? ? nil : row[6].to_s
                           )
        land_parcel_support = CultivableLandParcel.find_by_work_number(r.work_number_land_parcel_storage)
        # Create a campaign if not exist
        if r.campaign_name.present?
          campaign = Campaign.find_by_name(r.campaign_name)
          campaign ||= Campaign.create!(:name => r.campaign_name, :closed => false)
        end
        # Create an activity if not exist
        activity   = Activity.find_by_description(r.description)
        activity ||= Activity.create!(:nature => r.nature, :family => r.family, :name => r.name, :description => r.description)
        if r.product_nature_nomen
          product_nature_sup = ProductNature.find_by_nomen(r.product_nature_nomen)
          if product_nature_sup.present?
            product_nature_variant_sup = ProductNatureVariant.find_by_nature_id(product_nature_sup.id)
          else
            product_nature_sup = ProductNature.import_from_nomenclature(r.product_nature_nomen)
            product_nature_variant_sup = product_nature_sup.default_variant
          end
          if product_nature_variant_sup and land_parcel_support.present?
            pro = Production.where(:campaign_id => campaign.id, :activity_id => activity.id, :product_nature_id => product_nature_sup.id).first
            pro ||= activity.productions.create!(:product_nature_id => product_nature_sup.id, :campaign_id => campaign.id, :static_support => true)
            pro.supports.create!(:storage_id => land_parcel_support.id)
            plant_name = (Nomen::ProductNatures.find(r.product_nature_nomen).human_name + " " + campaign.name + " " + land_parcel_support.work_number)
            plant_work_nb = (r.product_nature_nomen.to_s + "-" + campaign.name + "-" + land_parcel_support.work_number)
            Plant.create!(:variant_id => product_nature_variant_sup.id, :work_number => plant_work_nb , :name => plant_name, :variety => product_nature_sup.variety, :born_at => Time.now, :owner_id => Entity.of_company.id)
          elsif product_nature_variant_sup
            pro = Production.where(:product_nature_id => product_nature_sup.id, :campaign_id => campaign.id, :activity_id => activity.id).first
            pro ||= activity.productions.create!(:product_nature_id => product_nature_sup.id, :campaign_id => campaign.id)
          end
        end
        print "."
      end
      puts "!"

      #############################################################################
      # import Bank Cash from CRCA
      #
      # TODO : Retrieve data and put it into bank_statement
      #
      # file = Rails.root.join("test", "fixtures", "files", "bank-rb.ofx")
      # FIXME OfxParser don't work....
      # ofx = OfxParser::OfxParser.parse(open(file))
      # ofx.bank_accounts.each do |bank_account|
      #   bank_account.id # => "492108"
      #   bank_account.bank_id # => "1837"
      #   bank_account.currency # => "GBP"
      #   bank_account.type # => :checking
      #   bank_account.balance.amount # => "100.00"
      #   bank_account.balance.amount_in_pennies # => "10000"
      # end
      # puts "!"


      ##############################################################################
      ## Demo data for fertilizing
      ##############################################################################

      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Procedures - demo data for fertilization reporting 2013: "
      campaign = Campaign.find_by_name("2013")
      sole_ble_nature = ProductNature.find_by_variety("triticum_aestivum")

      # create some indicator nature for fertilization
      # find some product for fertilization
      fertilizer_product = Product.find_by_variety("organic_matter")
      fertilizer_product_prev = Product.find_by_variety("organic_matter")
      # set indicator on product for fertilization

      #fertilizer_product.indicator_data.create!({:measure_unit => "kilograms_per_hectogram", :measured_at => Time.now }.merge(attributes))
      #fertilizer_product_prev.indicator_data.create!({:measure_unit => "kilograms_per_hectogram", :measured_at => Time.now }.merge(attributes))

      fertilizer_product.is_measured!(:nitrogen_concentration, 27.00.in_kilogram_per_hectogram, :at => Time.now)
      fertilizer_product.is_measured!(:potassium_concentration, 33.00.in_kilogram_per_hectogram, :at => Time.now)
      fertilizer_product.is_measured!(:phosphorus_concentration, 33.00.in_kilogram_per_hectogram, :at => Time.now)
      fertilizer_product_prev.is_measured!(:nitrogen_concentration, 27.00.in_kilogram_per_hectogram, :at => Time.now)
      fertilizer_product_prev.is_measured!(:potassium_concentration, 33.00.in_kilogram_per_hectogram, :at => Time.now)
      fertilizer_product_prev.is_measured!(:phosphorus_concentration, 33.00.in_kilogram_per_hectogram, :at => Time.now)


      production = Production.find_by_product_nature_id_and_campaign_id(sole_ble_nature.id, campaign.id)

      # provisional fertilization procedure
      procedure_prev = Procedure.create!(:natures => "soil_enrichment", :nomen =>"mineral_fertilizing", :production_id => production.id, :provisional => true )


      #plant = Plant.find_by_work_number("SOLE_BLE-2013-PC23")
      land_parcel_group_fert = CultivableLandParcel.find_by_work_number("PC23")
      # Create some procedure variable for fertilization
      for attributes in [{:target_id => land_parcel_group_fert.id, :role => "target",
                           :indicator => "net_surface_area",
                           :measure_quantity => "5.00", :measure_unit => "hectare"},
                         {:target_id => fertilizer_product_prev.id, :role => "input",
                           :indicator => "net_weight",
                           :measure_quantity => "475.00", :measure_unit => "kilogram"},
                         {:target_id => fertilizer_product_prev.id, :role => "input",
                           :indicator => "net_weight",
                           :measure_quantity => "275.00", :measure_unit => "kilogram"}
                        ]
        ProcedureVariable.create!({:procedure_id => procedure_prev.id}.merge(attributes) )
      end

      # Create some operation variable for fertilization
      for attributes in [{:started_at => (Time.now - 15.days), :stopped_at => (Time.now - 10.days)}]
        procedure_prev.operations.create!({:procedure_id => procedure_prev.id}.merge(attributes) )
      end

      # real fertilization procedure
      procedure_real = Procedure.create!(:natures => "soil_enrichment", :nomen =>"mineral_fertilizing", :production_id => production.id, :provisional_procedure_id => procedure_prev.id)


      #plant = Plant.find_by_work_number("SOLE_BLE-2013-PC23")
      land_parcel_group_fert = CultivableLandParcel.find_by_work_number("PC23")
      # Create some procedure variable for fertilization
      for attributes in [{:target_id => land_parcel_group_fert.id, :role => "target",
                           :indicator => "net_surface_area",
                           :measure_quantity => 5.0, :measure_unit => "hectare"},
                         {:target_id => fertilizer_product.id, :role => "input",
                           :indicator => "net_weight",
                           :measure_quantity => 575.00, :measure_unit => "kilogram"},
                         {:target_id => fertilizer_product.id, :role => "input",
                           :indicator => "net_weight",
                           :measure_quantity => 375.00, :measure_unit => "kilogram"}
                        ]
        ProcedureVariable.create!({:procedure_id => procedure_real.id}.merge(attributes) )
      end

      # Create some operation variable for fertilization
      for attributes in [{:started_at => (Time.now - 2.days), :stopped_at => Time.now}]
        procedure_real.operations.create!({:procedure_id => procedure_real.id}.merge(attributes) )
      end
      puts "!"


      ##############################################################################
      ## Demo data for animal treatment
      ##############################################################################
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Procedures - demo data for animal sanitary treatment reporting 2013: "

      worker_variant = ProductNature.import_from_nomenclature(:manager).default_variant
      worker = Worker.create!(:variant_id => worker_variant.id, :name => "Christian")

      worker_variant = ProductNature.import_from_nomenclature(:technician).default_variant
      worker = Worker.create!(:variant_id => worker_variant.id, :name => "Yvan")

      # add some credentials in preferences
      cattling_number = Preference.create!(:nature => :string, :name => "services.synel17.login", :value => "17387001")

      #sanitary_product_nature_variant = ProductNatureVariant.find_by_nature_name("Animal medicine")
      sanitary_product_nature_variant = ProductNature.import_from_nomenclature(:animal_medicine).default_variant
      campaign = Campaign.find_by_name("2013")
      animal_group_nature = ProductNature.find_by_nomen("female_adult_cow")
      animal_production = Production.find_by_product_nature_id_and_campaign_id(animal_group_nature.id, campaign.id)
      animal_production ||= Production.create!(:product_nature_id => animal_group_nature.id, :campaign_id => campaign.id, :activity_id => Activity.find_by_description("8200").id)
      # create an animal medicine product
      animal_medicine_product   = AnimalMedicine.find_by_name("acetal")
      animal_medicine_product ||= AnimalMedicine.create!(:name => "acetal", :identification_number => "FR_589698256352", :work_number => "FR_589698256352", :born_at => Time.now, :variant_id => sanitary_product_nature_variant.id, :owner_id => Entity.of_company.id)
      animal_medicine_product.is_measured!(:meat_withdrawal_period, 5.in_day, :at => Time.now)
      animal_medicine_product.is_measured!(:milk_withdrawal_period, 5.in_day, :at => Time.now)

      # import a document "prescription paper"
      document = Document.create!(:key => "20130724_prescription_001", :name => "prescritpion_001", :nature => "prescription" )
      File.open(Rails.root.join("test", "fixtures", "files", "prescription_1.jpg"),"rb") do |f|
        document.archive(f.read, :jpg)
      end

      # create a prescription
      prescription = Prescription.create!(:reference_number => "210000303",
                                          :prescriptor_id => Entity.last.id,
                                          :document_id => document.id,
                                          :delivered_on => "2012-10-24",
                                          :description => "Lotagen, Cobactan, Rotavec"
                                          )

      # select an animal to declare on an incident
      animal = Animal.last

      # Add an incident
      incident = animal.incidents.create!(:name => "Mammitte",
                                  :nature => "mammite",
                                  :observed_at => "2012-10-22",
                                  :description => "filament blanc lors de la traite",
                                  :priority => "5",
                                  :gravity => "3"
                                  )


      # treatment procedure
      procedure = incident.procedures.create!(:natures => "animal_care",
                                      :nomen =>"animal_treatment",
                                      :production_id => animal_production.id,
                                      :prescription_id => prescription.id
                                      )

      # Create some procedure variable
      for attributes in [{:target_id => worker.id, :role => "worker",
                           :indicator => "usage_duration",
                           :measure_quantity => "0.50", :measure_unit => "hour"},
                         {:target_id => animal_medicine_product.id, :role => "input",
                           :indicator => "net_volume",
                           :measure_quantity => "50.00", :measure_unit => "milliliter"},
                         {:target_id => animal.id, :role => "target",
                           :indicator => "population",
                           :measure_quantity => "1.00", :measure_unit => "unity"}
                        ]
        ProcedureVariable.create!({:procedure_id => procedure.id}.merge(attributes) )
      end

      # Create some operation variable
      for attributes in [{:started_at => (Time.now - 2.days), :stopped_at => Time.now}]
        procedure.operations.create!({:procedure_id => procedure.id}.merge(attributes) )
      end

      puts "!"

      ##############################################################################
      ## Demo data for document                                                   ##
      ##############################################################################
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Documents - demo data for documents 2013: "

      # import an outgoing_deliveries_journal in PDF"
      document = Document.create!(:key => "20130724_outgoing_001", :name => "outgoing_001", :nature => "outgoing_delivery_journal" )
      File.open(Rails.root.join("test", "fixtures", "files", "releve_apports.pdf"),"rb") do |f|
        document.archive(f.read, :pdf)
      end

      puts "!"

      puts "Total time: #{(Time.now - start).round(2)}s"

    end
  end
