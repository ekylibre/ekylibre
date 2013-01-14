# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class PricesController < AdminController

  unroll_all

  list(:conditions => prices_conditions, :order => :product_id) do |t|
    t.column :name, :through => :product, :url => true
    t.column :full_name, :through => :entity, :url => true
    t.column :name, :through => :category, :url => true
    t.column :pretax_amount, :currency => true
    t.column :amount, :currency => true
    t.column :by_default
    # t.column :range
    t.action :edit
    t.action :destroy
  end

  def new
    @mode = (params[:mode]||"sales").to_sym
    @price = Price.new(:product_id => params[:product_id], :currency => params[:currency]||Entity.of_company.currency, :category_id => params[:entity_category_id]||session[:current_entity_category_id]||0)
    @price.entity_id = params[:entity_id] if params[:entity_id]
    render_restfully_form
  end

  def create
    @mode = (params[:mode]||"sales").to_sym
    @price = Price.new(params[:price])
    @price.entity_id = params[:price][:entity_id]||Entity.of_company.id
    return if save_and_redirect(@price)
    render_restfully_form
  end

  def destroy
    return unless @price = find_and_check
    @price.destroy
    redirect_to_current
  end

  def find
    if params[:product_id] and params[:entity_id]
      return unless product = find_and_check(:product_natures, params[:product_id])
      return unless entity = find_and_check(:entity, params[:entity_id])
      @price = product.prices.find(:first, :conditions => {:entity_id => entity.id, :active => true}, :order => "by_default DESC")
      @price ||= Price.new(:category_id => entity.category_id)
      respond_to do |format|
        format.html { render :partial => "amount_form" }
        format.json { render :json => @price.to_json }
        format.xml  { render :xml => @price.to_xml }
      end
    elsif !params[:purchase_line_price_id].blank?
      return unless @price = find_and_check(:price, params[:purchase_line_price_id])
      @product = @price.product if @price
    elsif params[:purchase_line_product_id]
      return unless @product = find_and_check(:product_natures, params[:purchase_line_product_id])
      @price = @product.prices.find_by_active_and_by_default_and_entity_id(true, true, params[:entity_id]||Entity.of_company.id) if @product
    end
  end

  def edit
    return unless @price = find_and_check
    @mode = "purchases" if @price.entity_id != Entity.of_company.id
    t3e @price.attributes, :product => @price.product.name
    render_restfully_form
  end

  def update
    return unless @price = find_and_check
    @mode = "purchases" if @price.entity_id != Entity.of_company.id
    @price.amount = 0
    return if save_and_redirect(@price, :attributes => params[:price])
    t3e @price.attributes, :product => @price.product.name
    render_restfully_form
  end

  # Displays the main page with the list of prices
  def index
    @modes = ['all', 'clients', 'suppliers']
    @suppliers = Entity.where(:supplier => true)
    session[:entity_id] = 0
    if request.post?
      mode = params[:price][:mode]
      if mode == "suppliers"
        session[:entity_id] = params[:price][:supply].to_i
      elsif mode == "clients"
        session[:entity_id] = Entity.of_company.id
      else
        session[:entity_id] = 0
      end
    end
  end

  def export
    @products = ProductNature.availables
    @entity_categories = EntityCategory

    csv = ["",""]
    csv2 = ["Code Produit", "Nom"]
    @entity_categories.each do |category|
      csv += [category.code, category.name, ""]
      csv2 += ["HT","TTC","TVA"]
    end

    csv_string = Ekylibre::CSV.generate_line(csv)
    csv_string += Ekylibre::CSV.generate_line(csv2)

    csv_string += Ekylibre::CSV.generate do |csv|

      @products.each do |product|
        line = []
        line << [product.code, product.name]
        @entity_categories.each do |category|
          price = Price.find(:first, :conditions => {:active => true, :product_id => product.id, :category_id => EntityCategory.find_by_code(category.code).id})
          #raise Exception.new price.inspect
          if price.nil?
            line << ["","",""]
          else
            line << [price.pretax_amount.to_s.gsub(/\./,","), price.amount.to_s.gsub(/\./,","), price.tax.amount]
          end
        end
        csv << line.flatten
      end

    end

    send_data csv_string,
    :type  =>  'text/csv; charset=iso-8859-1; header=present',
    :disposition  =>  "attachment; filename=Tarifs.csv"

  end

  def import

    if request.post?
      if params[:csv_file].nil?
        notify_warning(:you_must_select_a_file_to_import)
        redirect_to :action => :import
      else
        file = params[:csv_file][:path]
        name = "MES_TARIFS.csv"
        @entity_categories = []
        @available_prices = []
        @unavailable_prices = []
        i = 0
        File.open("#{Rails.root.to_s}/#{name}", "w") { |f| f.write(file.read)}
        Ekylibre::CSV.foreach("#{Rails.root.to_s}/#{name}") do |row|
          if i == 0
            x = 2
            while !row[x].nil?
              entity_category = EntityCategory.find_by_code(row[x])
              entity_category = EntityCategory.create!(:code => row[x], :name => row[x+1]) if entity_category.nil?
              @entity_categories << entity_category
              x += 3
            end
          end

          if i > 1
            puts i.to_s+"hhhhhhhhhhhhhhh"
            x = 2
            @product = ProductNature.find_by_code(row[0])
            for category in @entity_categories
              blank = true
              tax = Tax.find(:first, :conditions => {:amount => row[x+2].to_s.gsub(/\,/,".").to_f})
              tax_id = tax.nil? ? nil : tax.id
              @price = Price.find(:first, :conditions => {:product_id => @product.id, :category_id => category.id, :active => true} )
              if @price.nil? and (!row[x].nil? or !row[x+1].nil? or !row[x+2].nil?)
                @price = Price.new(:pretax_amount => row[x].to_s.gsub(/\,/,".").to_f, :tax_id => tax_id, :amount => row[x+1].to_s.gsub(/\,/,".").to_f, :product_id => @product.id, :category_id => category.id, :entity_id => Entity.of_company.id, :currency => Entity.of_company.currency)
                blank = false
              elsif !@price.nil?
                blank = false
                @price.pretax_amount = row[x].to_s.gsub(/\,/,".").to_f
                @price.amount = row[x+1].to_s.gsub(/\,/,".").to_f
                @price.tax_id = tax_id
              end
              if blank == false
                if @price.valid?
                  @available_prices << @price
                else
                  @unavailable_prices << [i+1, @price.errors.full_messages]
                end
              end
              x += 3
            end
          end
          for price in @available_prices
            puts price.inspect+"    id" if price.id.nil? if i==14
          end
          #raise Exception.new @unavailable_prices.inspect if i == 12
          i += 1
        end

        if @unavailable_prices.empty?
          for price in @available_prices
            if price.id.nil?
              puts price.inspect
              Price.create!(price.attributes)
            else
              price.update_attributes(price.attributes)
            end
            notify_now(:prices_import_succeeded)
          end
        end
      end
    end

  end

end
