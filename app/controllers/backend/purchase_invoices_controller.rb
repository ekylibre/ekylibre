# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2012-2013 David Joulin, Brice Texier
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
  class PurchaseInvoicesController < Backend::BaseController
    manage_restfully planned_at: 'Time.zone.today+2'.c, redirect_to: '{action: :show, id: "id".c}'.c,
                     except: %i[new create update], continue: [:nature_id]

    respond_to :csv, :ods, :xlsx, :pdf, :odt, :docx, :html, :xml, :json

    unroll :number, :amount, :currency, :created_at, supplier: :full_name

    before_action :save_search_preference, only: :index


    def self.list_conditions
      code = ''
      code = search_conditions(purchase_invoice: %i[number reference_number created_at pretax_amount amount], entities: %i[number full_name]) + " ||= []\n"
      code << "if params[:period].present? && params[:period].to_s != 'all'\n"
      code << "  c[0] << ' AND #{PurchaseInvoice.table_name}.invoiced_at::DATE BETWEEN ? AND ?'\n"
      code << "  if params[:period].to_s == 'interval'\n"
      code << "    c << params[:started_on]\n"
      code << "    c << params[:stopped_on]\n"
      code << "  else\n"
      code << "    interval = params[:period].to_s.split('_')\n"
      code << "    c << interval.first\n"
      code << "    c << interval.second\n"
      code << "  end\n"
      code << "end\n"
      code << "if !params[:reconciliation_state].blank? && params[:reconciliation_state].to_s != 'all'\n"
      code << "  c[0] << ' AND #{Purchase.table_name}.reconciliation_state IN (?)'\n"
      code << "  c << params[:reconciliation_state]\n"
      code << "end\n"
      code << "if params[:responsible_id].to_i > 0\n"
      code << "  c[0] += ' AND #{PurchaseInvoice.table_name}.responsible_id = ?'\n"
      code << "  c << params[:responsible_id]\n"
      code << "end\n"
      code << "c\n "
      code << "if params[:payment_mode_id].to_i > 0\n"
      code << "  c[0] += ' AND #{Entity.table_name}.supplier_payment_mode_id = ?'\n"
      code << "  c << params[:payment_mode_id]\n"
      code << "end\n"
      code << "if params[:nature].present?\n"
      code << " if params[:nature] == 'unpaid'\n"
      code << "     c[0] << ' AND NOT #{PurchaseAffair.table_name}.closed'\n"
      code << " end\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    list(conditions: list_conditions, joins: %i[affair supplier], line_class: :status, order: { created_at: :desc, number: :desc }) do |t|
      t.action :payment_mode, on: :both, if: :payable?
      t.action :edit
      t.action :destroy
      t.column :number, url: :true
      t.column :invoiced_at
      t.column :reference_number, url: true
      t.column :supplier, url: true
      t.column :entity_payment_mode_name, through: :supplier, label: :supplier_payment_mode
      t.column :created_at
      t.status
      t.column :human_status, label: :state, hidden: true
      t.column :pretax_amount, currency: true, on_select: :sum, hidden: true
      t.column :amount, currency: true, on_select: :sum
    end
    # Mode de paiement du fournisseur

    list(:items, model: :purchase_items, order: { id: :asc }, conditions: { purchase_id: 'params[:id]'.c }) do |t|
      t.column :variant, url: { controller: 'RECORD.variant.class.name.tableize'.c, namespace: :backend }
      t.column :annotation
      t.column :first_reception_number, label: :reception, url: { controller: '/backend/receptions', id: 'RECORD.first_reception_id'.c }
      t.column :quantity
      t.column :unit_pretax_amount, currency: true
      t.column :unit_amount, currency: true, hidden: true
      t.column :reduction_percentage
      t.column :tax, url: true, hidden: true
      t.column :pretax_amount, currency: true
      t.column :amount, currency: true
      t.column :activity_budget, hidden: true
      t.column :team, hidden: true
      t.column :fixed_asset, url: true, hidden: true
    end

    list(:receptions, children: :items, conditions: { id: "PurchaseInvoice.find_by(id: params[:id]).receptions".c }) do |t|
      t.action :edit, if: :draft?
      t.action :destroy, if: :draft?
      t.column :number, url: true
      t.column :reference_number, url: true
      t.column :address, children: :product_name
      t.column :given_at, children: false
      # t.column :population, :datatype => :decimal
      # t.column :pretax_amount, currency: true
      # t.column :amount, currency: true
    end

    def show
      return unless @purchase_invoice = find_and_check
      respond_with(@purchase_invoice, methods: %i[taxes_amount affair_closed],
                   include: { delivery_address: { methods: [:mail_coordinate] },
                              supplier: { methods: [:picture_path], include: { default_mail_address: { methods: [:mail_coordinate] } } },
                              parcels: { include: :items },
                              affair: { methods: [:balance], include: [purchase_payments: { include: :mode }] },
                              items: { methods: %i[taxes_amount tax_name tax_short_label], include: [:variant] } }) do |format|
        format.html do
          t3e @purchase_invoice.attributes, supplier: @purchase_invoice.supplier.full_name, state: @purchase_invoice.state_label, label: @purchase_invoice.label
        end
      end
    end

    def new
      nature = PurchaseNature.find_by(id: params[:nature_id])
      nature ||= PurchaseNature.by_default

      @purchase_invoice = if params[:duplicate_of]
                            PurchaseInvoice.find_by(id: params[:duplicate_of])
                              .deep_clone(include: :items, except: %i[state number affair_id reference_number payment_delay])
                          elsif params[:reception_ids]
                            receptions = Reception.where(id: params[:reception_ids].split(','))
                            supplier_ids = receptions.pluck(:sender_id)
                            supplier_id = supplier_ids.uniq.first
                            invoice_attributes = {
                              nature: nature,
                              supplier_id: supplier_id,
                              reconciliation_state: 'reconcile',
                              items: InvoiceableItemsFilter.new.filter(receptions)
                            }
                            PurchaseInvoice.new(invoice_attributes)
                          else
                            PurchaseInvoice.new(nature: nature)
                          end

      @purchase_invoice.currency = @purchase_invoice.nature.currency
      @purchase_invoice.responsible ||= current_user
      @purchase_invoice.planned_at = Time.zone.now
      @purchase_invoice.supplier_id ||= params[:supplier_id] if params[:supplier_id]

      if (address = Entity.of_company.default_mail_address)
        @purchase_invoice.delivery_address = address
      end

      render locals: { with_continue: true }
    end

    def create
      if permitted_params[:items_attributes].present?
        permitted_params[:items_attributes].each do |_key, item_attribute|
          ids = item_attribute[:parcels_purchase_invoice_items]
          parcel_item_ids = ids.blank? ? [] : JSON.parse(ids)
          unreconciled_parcel_items = ParcelItem.where(id: parcel_item_ids).reject { |parcel_item| parcel_item.purchase_invoice_item }
          item_attribute[:parcels_purchase_invoice_items] = unreconciled_parcel_items
        end
      end

      @purchase_invoice = PurchaseInvoice.new(permitted_params)

      url = if params[:create_and_continue]
              { action: :new, continue: true }
            else
              params[:redirect] || { action: :show, id: 'id'.c }
            end

      if @purchase_invoice.items.blank?
        notify_error_now :purchase_invoice_need_at_least_one_item
      else
        return if save_and_redirect(@purchase_invoice, url: url, notify: :record_x_created, identifier: :number)
      end
      render(locals: { cancel_url: { action: :index }, with_continue: true })
    end

    def update
      return unless (@purchase_invoice = find_and_check)

      if @purchase_invoice.linked_to_tax_declaration?
        notify_error(:unable_to_modify_purchase_invoice_link_to_tax_declaration)
        return redirect_to_back fallback_location: { action: :show, id: @purchase_invoice.id }
      end

      if permitted_params[:items_attributes].present?
        permitted_params[:items_attributes].each do |_key, item_attribute|
          ids = item_attribute[:parcels_purchase_invoice_items]
          parcel_item_ids = ids.blank? ? [] : JSON.parse(ids)
          item_attribute[:parcels_purchase_invoice_items] = ParcelItem.find(parcel_item_ids)
        end
      end

      @purchase_invoice.assign_attributes(permitted_params)

      if @purchase_invoice.items.all?(&:marked_for_destruction?)
        notify_error_now :purchase_invoice_need_at_least_one_item
      elsif @purchase_invoice.save
        return redirect_to(params[:redirect] || { action: :show, id: @purchase_invoice.id },
                           notify: :record_x_updated,
                           identifier: :number)
      end
      render :edit
    end

    def edit
      return unless (@purchase_invoice = find_and_check)

      if @purchase_invoice.updateable? && @purchase_invoice.linked_to_tax_declaration?
        notify_warning_now(:unable_to_modify_purchase_invoice_link_to_tax_declaration)
      end

      super
    end

    def destroy
      return unless (@purchase_invoice = find_and_check)

      if @purchase_invoice.linked_to_tax_declaration?
        notify_error(:unable_to_modify_purchase_invoice_link_to_tax_declaration)
        return redirect_to_back fallback_location: { action: :show, id: @purchase_invoice.id }
      end

      super
    end

    def payment_mode
      # use view to select payment mode for mass payment on purchase
    end

    def pay
      unless (mode = OutgoingPaymentMode.find_by(id: params[:mode_id]))
        notify_error :need_a_valid_payment_mode
        redirect_to action: :index
        return
      end
      purchases = find_purchases
      return unless purchases

      unless purchases.all?
        notify_error(:all_purchases_must_be_ordered_or_invoiced)
        redirect_to(params[:redirect] || { action: :index })
        return
      end

      if mode.sepa?
        unless purchases.all?(&:sepable?)
          notify_error(:purchases_invalid_for_sepa)
          redirect_to(params[:redirect] || { action: :index })
          return
        end
      end

      payments_list = OutgoingPaymentList.build_from_purchases(
        purchases,
        mode,
        current_user
      )

      if payments_list.save
        redirect_to backend_outgoing_payment_lists_path
      else
        notify_error(payments_list.errors.full_messages.join(', '))
        redirect_to(params[:redirect] || { action: :index })
      end
    end

    protected

      def find_purchases
        purchase_ids = params[:id].split(',')
        purchases = purchase_ids.map { |id| PurchaseInvoice.find_by(id: id) }.compact
        unless purchases.any?
          notify_error :no_purchases_given
          redirect_to(params[:redirect] || { action: :index })
          return nil
        end
        purchases
      end
  end
end
