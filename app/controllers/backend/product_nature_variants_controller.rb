# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class ProductNatureVariantsController < Backend::BaseController
    manage_restfully active: true
    manage_restfully_incorporation
    manage_restfully_picture

    unroll :name, :unit_name, :number

    # params:
    #   :q Text search
    #   :working_set
    #   :nature_id
    #   :category_id
    def self.variants_conditions
      code = search_conditions(product_nature_variants: %i[name number]) + " ||= []\n"
      code << "unless params[:working_set].blank?\n"
      code << "  item = Nomen::WorkingSet.find(params[:working_set])\n"
      code << "  c[0] << \" AND product_nature_variants.nature_id IN (SELECT id FROM product_natures WHERE \#{WorkingSet.to_sql(item.expression)})\"\n"
      code << "end\n"
      code << "if params[:nature_id].to_i > 0\n"
      code << "  c[0] << \" AND product_nature_variants.nature_id = ?\"\n"
      code << "  c << params[:nature_id].to_i\n"
      code << "end\n"
      code << "if params[:category_id].to_i > 0\n"
      code << "  c[0] << \" AND product_nature_variants.category_id = ?\"\n"
      code << "  c << params[:category_id].to_i\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: variants_conditions) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :number
      t.column :nature, url: true
      t.column :category, url: true
      t.column :current_stock
      t.column :current_outgoing_stock_ordered_not_delivered
      t.column :unit_name
      t.column :variety
      t.column :derivative_of
      t.column :active
    end

    list(:catalog_items, conditions: { variant_id: 'params[:id]'.c }) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :amount, url: true, currency: true
      t.column :all_taxes_included
      t.column :catalog, url: true
    end

    list(:products, conditions: { variant_id: 'params[:id]'.c }, order: { born_at: :desc }) do |t|
      t.column :name, url: true
      t.column :work_number
      t.column :identification_number
      t.column :born_at, datatype: :datetime
      t.column :population
      t.column :unit_name
      t.column :net_mass
      t.column :net_volume
    end

    list(:sale_items, conditions: { variant_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :number, through: :sale, url: true
      t.column :invoiced_at, through: :sale, datatype: :datetime
      t.column :quantity
      t.column :reduction_percentage
      t.column :unit_pretax_amount
    end

    list(:parcel_items, conditions: { variant_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :number, through: :parcel, url: true
      t.column :planned_at, through: :parcel, datatype: :datetime
      t.column :population
    end

    list(:components, model: :product_nature_variant_component, conditions: { product_nature_variant_id: 'params[:id]'.c }, order: { parent_id: :desc }) do |t|
      t.column :name
      t.column :part_product_nature_variant, url: true
    end

    # Returns quantifiers for a given variant
    def quantifiers
      return unless @product_nature_variant = find_and_check
    end

    def detail
      return unless @product_nature_variant = find_and_check
      product_nature = @product_nature_variant.nature
      infos = {
        name: @product_nature_variant.name,
        number: @product_nature_variant.number,
        depreciable: @product_nature_variant.depreciable?,
        unit: {
          name: @product_nature_variant.unit_name
        }
      }
      if product_nature.subscribing?
        entity = nil
        address = nil
        if params[:sale_address_id] || params[:purchase_address_id]
          address = EntityAddress.mails.find_by(id: params[:sale_address_id] || params[:purchase_address_id])
        end
        if params[:sale_client_id] || params[:purchase_supplier_id]
          entity = Entity.find_by(id: params[:sale_client_id] || params[:purchase_supplier_id])
        end
        entity ||= address.entity if address
        started_on = Time.zone.today
        subscription_nature = product_nature.subscription_nature
        if entity
          last_subscription = entity.last_subscription(subscription_nature)
          started_on = last_subscription.stopped_on + 1 if last_subscription
        end
        address ||= entity.default_mail_address if entity
        stopped_on = product_nature.subscription_stopped_on(started_on)
        infos[:subscription] = {
          nature_name: subscription_nature.name,
          started_on: started_on,
          stopped_on: stopped_on
        }
        infos[:subscription][:address_id] = address.id if address
      end
      if @product_nature_variant.picture.file?
        infos[:picture] = @product_nature_variant.picture.url(:thumb)
      end
      if pictogram = @product_nature_variant.category.pictogram
        infos[:pictogram] = pictogram
      end
      catalog = nil
      if params[:catalog_id]
        catalog = Catalog.find(params[:catalog_id])
      elsif params[:sale_nature_id]
        catalog = SaleNature.find(params[:sale_nature_id]).catalog
      end
      if catalog && item = catalog.items.find_by(variant_id: @product_nature_variant.id)
        infos[:all_taxes_included] = item.all_taxes_included
        unless infos[:tax_id] = (item.reference_tax ? item.reference_tax.id : nil)
          infos[:tax_id] = if (items = SaleItem.where(variant_id: @product_nature_variant.id)) && items.any?
                             items.order(id: :desc).first.tax_id
                           elsif @product_nature_variant.category.sale_taxes.any?
                             @product_nature_variant.category.sale_taxes.first.id
                           else
                             Tax.current.first.id
                           end
        end
        if tax = Tax.find_by(id: infos[:tax_id])
          if item.all_taxes_included
            infos[:unit][:pretax_amount] = tax.pretax_amount_of(item.amount)
            infos[:unit][:amount] = item.amount
          else
            infos[:unit][:pretax_amount] = item.amount
            infos[:unit][:amount] = tax.amount_of(item.amount)
          end
        end
      elsif params[:mode] == 'last_purchase_item'
        # get last item with tax, pretax amount and amount
        if (items = PurchaseItem.where(variant_id: @product_nature_variant.id)) && items.any?
          item = items.order(id: :desc).first
          infos[:tax_id] = item.tax_id
          infos[:unit][:pretax_amount] = item.unit_pretax_amount
          infos[:unit][:amount] = item.unit_amount
        # or get tax and amount from catalog
        elsif (items = @product_nature_variant.catalog_items.of_usage(:purchase)) && items.any?
          if item.all_taxes_included
            infos[:unit][:pretax_amount] = item.reference_tax.pretax_amount_of(item.amount)
            infos[:unit][:amount] = item.amount
          else
            infos[:unit][:pretax_amount] = item.amount
            infos[:unit][:amount] = item.reference_tax.amount_of(item.amount)
          end
        # or get tax from category
        elsif @product_nature_variant.category.sale_taxes.any?
          infos[:tax_id] = @product_nature_variant.category.sale_taxes.first.id
        end
      elsif params[:mode] == 'last_sale_item'
        # get last item with tax, pretax amount and amount
        if (items = SaleItem.where(variant_id: @product_nature_variant.id)) && items.any?
          item = items.order(id: :desc).first
          infos[:tax_id] = item.tax_id
          infos[:unit][:pretax_amount] = item.unit_pretax_amount
          infos[:unit][:amount] = item.unit_amount
        # or get tax and amount from catalog
        elsif (items = @product_nature_variant.catalog_items.of_usage(:sale)) && items.any?
          if item.all_taxes_included
            infos[:unit][:pretax_amount] = item.reference_tax.pretax_amount_of(item.amount)
            infos[:unit][:amount] = item.amount
          else
            infos[:unit][:pretax_amount] = item.amount
            infos[:unit][:amount] = item.reference_tax.amount_of(item.amount)
          end
        # or get tax from category
        elsif @product_nature_variant.category.purchase_taxes.any?
          infos[:tax_id] = @product_nature_variant.category.purchase_taxes.first.id
        end
      end
      render json: infos
    end
  end
end
