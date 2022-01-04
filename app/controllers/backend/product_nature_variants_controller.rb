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
    include Pickable

    manage_restfully except: %i[edit create update show new], active: true
    manage_restfully_picture

    # To edit it, change here the column and edit action.yml unrolls section
    unroll :name, :unit_name, category: { charge_account: :number }
    unroll :name, :unit_name, method: :unroll_saleables, category: { product_account: :number }

    # params:
    #   :q Text search
    #   :working_set
    #   :nature_id
    #   :category_id
    def self.variants_conditions
      code = search_conditions(product_nature_variants: %i[name number work_number]) + " ||= []\n"
      code << "unless params[:working_set_id].blank?\n"
      code << "  item = Onoma::WorkingSet.find(params[:working_set_id])\n"
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
      code << "if controller_name == 'article_variants'\n"
      code << "  c[0] << \" AND product_nature_variants.type = ?\"\n"
      code << "  c << 'Variants::ArticleVariant'\n"
      code << "elsif controller_name == 'equipment_variants'\n"
      code << "  c[0] << \" AND product_nature_variants.type = ?\"\n"
      code << "  c << 'Variants::EquipmentVariant'\n"
      code << "end\n"
      code << "if params[:s] == 'active'\n"
      code << "  c[0] += ' AND product_nature_variants.active = ?'\n"
      code << "  c << true\n"
      code << "elsif params[:s] == 'inactive'\n"
      code << "  c[0] += ' AND product_nature_variants.active = ?'\n"
      code << "  c << false\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: variants_conditions) do |t|
      t.action :edit, url: { controller: '/backend/product_nature_variants' }
      t.action :destroy, if: :destroyable?, url: { controller: '/backend/product_nature_variants' }
      t.column :active
      t.column :name, url: { namespace: :backend }
      t.column :number
      t.column :work_number, hidden: true
      t.column :nature, hidden: true, url: { controller: '/backend/product_natures' }
      t.column :category, url: { controller: '/backend/product_nature_categories' }
      t.column :current_stock_displayed, label: :current_stock
      # t.column :current_outgoing_stock_ordered_not_delivered_displayed
      t.column :unit_name, label: :unit
      t.column :variety
      t.column :derivative_of
    end

    list(:catalog_items, conditions: { variant_id: 'params[:id]'.c }) do |t|
      t.action :edit, url: { controller: '/backend/catalog_items' }
      t.action :destroy, url: { controller: '/backend/catalog_items' }
      t.column :name, url: { controller: '/backend/catalog_items' }
      t.column :unit
      t.column :amount, url: { controller: '/backend/catalog_items' }, currency: true
      t.column :all_taxes_included
      t.column :catalog, url: { controller: '/backend/catalogs' }
      t.column :started_at
      t.column :stopped_at
    end

    list(:products, scope: [:alive], conditions: { variant_id: 'params[:id]'.c }, order: { born_at: :desc }) do |t|
      t.column :name, url: { controller: '/backend/products' }
      t.column :work_number
      t.column :identification_number
      t.column :born_at, datatype: :datetime
      t.column :population
      t.column :conditioning_unit
    end

    list(:sale_items, conditions: { variant_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :number, through: :sale, url: { controller: '/backend/sales' }
      t.column :invoiced_at, through: :sale, datatype: :datetime
      t.column :conditioning_unit
      t.column :conditioning_quantity
      t.column :unit_pretax_amount
      t.column :reduction_percentage
      t.column :tax, hidden: true
      t.column :pretax_amount
      t.column :amount
    end

    list(:purchase_invoice_items, model: :purchase_item, joins: :purchase, conditions: [
      "variant_id = ? AND purchases.type = 'PurchaseInvoice'", 'params[:id]'.c]) do |t|
      t.column :number, through: :purchase, url: { controller: '/backend/purchases' }
      t.column :invoiced_at, through: :purchase, datatype: :datetime
      t.column :conditioning_unit
      t.column :conditioning_quantity
      t.column :unit_pretax_amount
      t.column :unit_amount, hidden: true
      t.column :reduction_percentage
      t.column :tax, hidden: true
      t.column :pretax_amount
      t.column :amount
      t.column :supplier, label_method: 'supplier.full_name', url: { controller: '/backend/entities', action: :show, id: 'RECORD.supplier.id'.c }
    end

    list(:purchase_order_items, model: :purchase_item, joins: :purchase, conditions: [
      "variant_id = ? AND purchases.type = 'PurchaseOrder'", 'params[:id]'.c]) do |t|
      t.column :number, through: :purchase, url: { controller: '/backend/purchases' }
      t.column :ordered_at, through: :purchase, datatype: :datetime
      t.column :conditioning_unit
      t.column :conditioning_quantity
      t.column :unit_pretax_amount
      t.column :unit_amount, hidden: true
      t.column :reduction_percentage
      t.column :tax, hidden: true
      t.column :pretax_amount
      t.column :amount
      t.column :supplier, label_method: 'supplier.full_name', url: { controller: '/backend/entities', action: :show, id: 'RECORD.supplier.id'.c }
    end

    list(:receptions, model: :parcel_item_storings, joins: :parcel_item, conditions: ['parcel_items.variant_id = ?', 'params[:id]'.c], order: { created_at: :desc }) do |t|
      t.column :reception_number, through: :parcel_item, label: :number, url: { controller: '/backend/receptions', action: :show, id: 'RECORD.parcel_item.parcel_id'.c }
      t.column :reception_planned_at, through: :parcel_item, datatype: :datetime
      t.column :reception_given_at, through: :parcel_item, datatype: :datetime
      t.column :product, url: { controller: '/backend/products' }
      t.column :storage, url: { controller: '/backend/products' }
      t.column :conditioning_unit
      t.column :conditioning_quantity
      t.column :unit_pretax_amount, through: :parcel_item, hidden: true
      t.column :sender, label_method: 'sender.full_name', through: :parcel_item, label: :supplier, url: { controller: '/backend/entities', action: :show, id: 'RECORD.parcel_item.sender.id'.c }
    end

    list(:shipments, model: :shipment_items, conditions: { variant_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :number, through: :shipment, url: { controller: '/backend/shipments' }
      t.column :planned_at, through: :shipment, datatype: :datetime
      t.column :conditioning_unit
      t.column :conditioning_quantity
    end

    list(:suppliers,
         model: :purchase_items,
         select: [['pnv_infos.supplier_name', 'supplier_name'],
                  ['pnv_infos.entity_id', 'entity_id'],
                  ['pnv_infos.variant_id', 'variant_id'],
                  ['pnv_infos.ordered_quantity', 'ordered_quantity'],
                  ['pnv_infos.average_unit_pretax_amount', 'average_unit_pretax_amount'],
                  ['pnv_infos.last_unit_pretax_amount', 'last_unit_pretax_amount']],
         joins: 'INNER JOIN product_nature_variant_suppliers_infos pnv_infos
                 ON purchase_items.variant_id = pnv_infos.variant_id',
         conditions: ['pnv_infos.variant_id = ?', 'params[:id]'.c],
         count: 'supplier_name',
         group: 'supplier_name,
                 pnv_infos.entity_id,
                 pnv_infos.variant_id,
                 ordered_quantity,
                 average_unit_pretax_amount,
                 last_unit_pretax_amount',
         order: 'supplier_name') do |t|
      t.column :supplier_name, label: :name, url: { controller: '/backend/entities', action: :show, id: 'RECORD.entity_id'.c }
      t.column :ordered_quantity
      t.column :average_unit_pretax_amount
      t.column :last_unit_pretax_amount
      t.action :order_again, icon_name: 'cart-plus', url: { controller: '/backend/purchase_orders', action: :new, supplier_id: 'RECORD.entity_id'.c, items_attributes: [{ variant_id: 'params[:id]'.c, role: 'merchandise' }], display_items_form: true }
    end

    list(:components, model: :product_nature_variant_component, conditions: { product_nature_variant_id: 'params[:id]'.c }, order: { parent_id: :desc }) do |t|
      t.column :name
      t.column :part_product_nature_variant, url: { controller: 'RECORD.product_nature_variant.class.name.tableize'.c, namespace: :backend }
    end

    # Returns quantifiers for a given variant
    def quantifiers
      return unless @product_nature_variant = find_and_check
    end

    def detail
      return unless @product_nature_variant = find_and_check

      product_nature = @product_nature_variant.nature
      stock = @product_nature_variant.current_stock(into_default_unit: true)
      conditioning = Unit.find_by_id(params[:conditioning_id])
      conditioning ||= @product_nature_variant&.default_unit
      reference_date = params[:reference_date].present? ? DateTime.parse(params[:reference_date]) : Time.now

      infos = {
        name: @product_nature_variant.name,
        number: @product_nature_variant.number,
        depreciable: @product_nature_variant.depreciable?,
        unit: {
          name: @product_nature_variant.unit_name
        },
        stock: @product_nature_variant.current_stock,
        default_unit_name: @product_nature_variant.default_unit_name.l.pluralize(stock == 0 ? 1 : stock),
        default_unit_stock: stock,
        default_unit_id: @product_nature_variant.default_unit_id,
        is_equipment: @product_nature_variant.is_a?(::Variants::EquipmentVariant)
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
      catalog_item = catalog ? catalog.items.of_variant(@product_nature_variant).of_unit(conditioning).active_at(reference_date).first : nil
      if params[:mode] == 'use_sale_catalog'
        sale_nature = params[:sale_nature_id] ? SaleNature.find_by_id(params[:sale_nature_id]) : SaleNature.first
        if (items = sale_nature.catalog.items.of_unit(conditioning).of_variant(@product_nature_variant).active_at(reference_date)).any?
          item = items.first
          infos[:all_taxes_included] = item.all_taxes_included
          infos[:unit][:pretax_amount] = item.pretax_amount
          infos[:unit][:amount] = item.amount
          infos[:tax_id] = item.reference_tax_id
        end
      elsif params[:mode] == 'last_sale_item'
        # get last item with tax, pretax amount and amount
        sale_nature = params[:sale_nature_id] ? SaleNature.find_by_id(params[:sale_nature_id]) : SaleNature.first
        if (items = SaleItem.of_sale_nature(sale_nature).where(variant: @product_nature_variant, conditioning_unit: conditioning)).any?
          item = items.order(id: :desc).first
          infos[:tax_id] = item.tax_id
          infos[:unit][:pretax_amount] = item.unit_pretax_amount
          infos[:unit][:amount] = item.unit_amount
        end
      elsif catalog_item
        infos[:all_taxes_included] = catalog_item.all_taxes_included
        unless infos[:tax_id] = (catalog_item.reference_tax ? catalog_item.reference_tax.id : nil)
          infos[:tax_id] = if (items = SaleItem.where(variant_id: @product_nature_variant.id)) && items.any?
                             items.order(id: :desc).first.tax_id
                           elsif @product_nature_variant.category.sale_taxes.any?
                             @product_nature_variant.category.sale_taxes.first.id
                           else
                             Tax.current.first.id
                           end
        end
        if tax = Tax.find_by(id: infos[:tax_id])
          if catalog_item.all_taxes_included
            infos[:unit][:pretax_amount] = tax.pretax_amount_of(catalog_item.amount)
            infos[:unit][:amount] = catalog_item.amount
          else
            infos[:unit][:pretax_amount] = catalog_item.amount
            infos[:unit][:amount] = tax.amount_of(catalog_item.amount)
          end
        end
      elsif params[:mode] == 'last_purchase_item'
        # get last item with tax, pretax amount and amount
        if (items = PurchaseItem.where(variant: @product_nature_variant, conditioning_unit: conditioning)).any?
          item = items.order(id: :desc).first
          infos[:tax_id] = item.tax_id
          infos[:unit][:pretax_amount] = item.unit_pretax_amount
          infos[:unit][:amount] = item.unit_amount
        # or get tax and amount from catalog
        elsif (items = @product_nature_variant.catalog_items.of_usage(:purchase).of_unit(conditioning).active_at(reference_date)).any?
          item = items.order(id: :desc).first
          if item.all_taxes_included
            infos[:unit][:pretax_amount] = item.reference_tax.pretax_amount_of(item.amount)
            infos[:unit][:amount] = item.amount
          else
            infos[:unit][:pretax_amount] = item.amount
            infos[:unit][:amount] = item.reference_tax&.amount_of(item.amount)
          end
        # or get tax from category
        elsif @product_nature_variant.category.sale_taxes.any?
          infos[:tax_id] = @product_nature_variant.category.sale_taxes.first.id
        end
      end
      infos[:unit][:pretax_amount] = 0 unless infos.dig(:unit, :pretax_amount)
      render json: infos
    end

    def storage_detail
      quantity = ParcelItemStoring.where(storage_id: params[:storage_id])
                                  .joins(:parcel_item)
                                  .where(parcel_items: { variant_id: params[:id] })
                                  .joins(parcel_item: :parcel)
                                  .where(parcels: { state: 'given' })
                                  .sum(:quantity)
      variant = ProductNatureVariant.find(params[:id])
      storage = Product.find(params[:storage_id])
      stock = quantity * variant.default_quantity
      unit = variant.default_unit_name.l.pluralize(stock == 0 ? 1 : stock)
      render json: { quantity: stock, unit: unit, name: storage.name }
    end

    def show
      instance_variable_set("@#{controller_name.singularize}", find_and_check(model: :product_nature_variant))
      t3e(instance_variable_get("@#{controller_name.singularize}").attributes)
    end

    def edit
      @product_nature_variant = find_and_check
      @form_url = backend_product_nature_variant_path(@product_nature_variant)
      @key = 'product_nature_variant'
      t3e(@product_nature_variant.attributes)
    end

    def new
      model_klass = controller_path.gsub('backend/', '').classify.constantize
      attributes = {}

      nature_id = if params.key?(:nature_id)
                    params[:nature_id]
                  else
                    pnv = params.permit(product_nature_variant: [:nature_id])
                                .to_h
                                .fetch(:product_nature_variant, {})

                    pnv.is_a?(Hash) ? pnv.fetch(:nature_id, nil) : nil
                  end

      if nature_id.present? && (nature = ProductNature.find_by(id: nature_id)).present?
        type_allocator = Variant::TypeAllocatorService.new(nature: nature)
        model_klass = type_allocator.find_type.constantize
        attributes[:nature] = nature
      else
        @submit_label = :next.tl
        @form_url = { action: :new }
        @form_method = :get
      end

      instance_variable_set("@#{controller_name.singularize}", model_klass.new(attributes))
      @key = :product_nature_variant
    end

    def create
      instance_variable_set("@#{controller_name.singularize}", controller_path.gsub('backend/', '').classify.constantize.new(permitted_params))
      @key = :product_nature_variant
      handle_maaid(instance_variable_get("@#{controller_name.singularize}"), params[:phyto_product_id])
      return if save_and_redirect(instance_variable_get("@#{controller_name.singularize}"), url: (params[:create_and_continue] ? { action: :new, continue: true } : (params[:redirect] || { action: :show, id: 'id'.c })), notify: ((params[:create_and_continue] || params[:redirect]) ? :record_x_created : false), identifier: :name)

      render(locals: { cancel_url: { action: :index }, with_continue: false })
    end

    def update
      return unless @product_nature_variant = find_and_check(:product_nature_variant)

      t3e(@product_nature_variant.attributes)
      @product_nature_variant.attributes = permitted_params
      handle_maaid(@product_nature_variant, params[:phyto_product_id])
      return if save_and_redirect(@product_nature_variant, url: params[:redirect] || { action: :show, id: 'id'.c }, notify: (params[:redirect] ? :record_x_updated : false), identifier: :name)

      @form_url = backend_product_nature_variant_path(@product_nature_variant)
      @key = 'product_nature_variant'
      render(locals: { cancel_url: { action: :index }, with_continue: false })
    end

    private

      def handle_maaid(variant, phyto_product_id)
        if phyto_product_id.present?
          phyto = RegisteredPhytosanitaryProduct.find(phyto_product_id)
          attributes = { france_maaid: phyto.france_maaid, reference_name: phyto.reference_name, imported_from: 'Lexicon' }
          variant.attributes = attributes
        end
      end
  end
end
