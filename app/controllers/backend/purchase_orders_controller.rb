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
  class PurchaseOrdersController < Backend::BaseController
    manage_restfully planned_at: 'Time.zone.today+2'.c, redirect_to: '{action: :show, id: "id".c}'.c,
                     except: %i[new create], continue: [:nature_id]

    unroll :number, :reference_number, :ordered_at, :pretax_amount, supplier: :full_name

    before_action :save_search_preference, only: :index

    def self.list_conditions
      code = ''
      code = search_conditions(purchase_order: %i[number reference_number created_at pretax_amount], entities: %i[number full_name]) + " ||= []\n"
      code << "if params[:period].present? && params[:period].to_s != 'all'\n"
      code << "  c[0] << ' AND #{PurchaseOrder.table_name}.ordered_at::DATE BETWEEN ? AND ?'\n"
      code << "  if params[:period].to_s == 'interval'\n"
      code << "    c << params[:started_on]\n"
      code << "    c << params[:stopped_on]\n"
      code << "  else\n"
      code << "    interval = params[:period].to_s.split('_')\n"
      code << "    c << interval.first\n"
      code << "    c << interval.second\n"
      code << "  end\n"
      code << "end\n"
      code << "if params[:state].is_a?(Array) && !params[:state].empty?\n"
      code << "  c[0] << ' AND #{PurchaseOrder.table_name}.state IN (?)'\n"
      code << "  c << params[:state]\n"
      code << "end\n "
      code << "if params[:responsible_id].to_i > 0\n"
      code << "  c[0] += ' AND #{PurchaseOrder.table_name}.responsible_id = ?'\n"
      code << "  c << params[:responsible_id]\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    list(conditions: list_conditions, joins: :supplier, order: { created_at: :desc, number: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: :true
      t.column :reference_number, url: true
      t.column :created_at
      t.column :supplier, url: true
      t.column :pretax_amount, currency: true, on_select: :sum
      t.column :amount, currency: true, on_select: :sum
    end

    list(:items, model: :purchase_items, order: { id: :asc }, conditions: { purchase_id: 'params[:id]'.c }) do |t|
      t.column :variant, label_method: :name_with_unit, url: { controller: 'RECORD.variant.class.name.tableize'.c, namespace: :backend }
      t.column :annotation, hidden: true
      t.column :first_reception_number, label: :reception, url: { controller: '/backend/receptions', id: 'RECORD.first_reception_id'.c }
      t.column :conditioning_unit
      t.column :conditioning_quantity, class: 'right-align'
      t.column :human_received_quantity, label: :received_quantity, datatype: :decimal, class: 'right-align'
      t.column :human_quantity_to_receive, label: :quantity_to_receive, datatype: :decimal, class: 'right-align'
      t.column :unit_pretax_amount, currency: true, class: 'right-align'
      t.column :unit_amount, currency: true, hidden: true
      t.column :reduction_percentage, class: 'right-align'
      t.column :tax, url: true, hidden: true, class: 'right-align'
      t.column :pretax_amount, currency: true, class: 'right-align'
      t.column :amount, currency: true, class: 'right-align'
      t.column :activity_budget, hidden: true
      t.column :team, hidden: true
      t.column :fixed_asset, url: true, hidden: true
    end

    def show
      return unless @purchase_order = find_and_check

      respond_to do |format|
        format.html do
          t3e @purchase_order.attributes, supplier: @purchase_order.supplier.full_name, state: @purchase_order.state_label, label: @purchase_order.label
        end
        format.odt do
          return unless template = DocumentTemplate.find_active_template(:purchases_order, 'odt')

          printer = Printers::PurchaseOrderPrinter.new(template: template, purchase_order: @purchase_order)
          generator = Ekylibre::DocumentManagement::DocumentGenerator.build
          odt_data = generator.generate_odt(template: template, printer: printer)

          send_data odt_data, filename: "#{printer.document_name}.odt"
        end
        format.pdf do
          return unless template = find_and_check(:document_template, params[:template])

          printer = Printers::PurchaseOrderPrinter.new(template: template, purchase_order: @purchase_order)
          generator = Ekylibre::DocumentManagement::DocumentGenerator.build
          pdf_data = generator.generate_pdf(template: template, printer: printer)
          archiver = Ekylibre::DocumentManagement::DocumentArchiver.build

          archiver.archive_document(pdf_content: pdf_data, template: template, key: printer.key, name: printer.document_name)

          send_data pdf_data, filename: "#{printer.document_name}.pdf", type: 'application/pdf', disposition: 'attachment'
        end
      end
    end

    def new
      nature = PurchaseNature.by_default
      @purchase_order = PurchaseOrder.new(nature: nature)
      @purchase_order.currency = @purchase_order.nature.currency
      @purchase_order.responsible ||= current_user
      @purchase_order.planned_at = Time.zone.now
      @purchase_order.ordered_at = Time.zone.now
      @purchase_order.supplier_id ||= params[:supplier_id] if params[:supplier_id]

      if (address = Entity.of_company.default_mail_address)
        @purchase_order.delivery_address = address
      end

      if (items_attributes = params[:items_attributes])
        items_attributes.each { |item| @purchase_order.items.build(variant_id: item[:variant_id], role: item[:role])}
      end

      @display_items_form = true if params[:display_items_form]

      render locals: { with_continue: true }
    end

    def create
      @purchase_order = PurchaseOrder.new(permitted_params)

      if @purchase_order.items.blank?
        @purchase_order.validate(:perform_validations)
        notify_error_now :purchase_order_need_at_least_one_item
      else
        return if save_and_redirect(@purchase_order,
                                    url: (params[:create_and_continue] ? { action: :new, continue: true, nature_id: @purchase_order.nature_id } : (params[:redirect] || { action: :show, id: "id".c })),
                                    notify: :record_x_created, identifier: :number)
      end
      render(locals: { cancel_url: { action: :index }, with_continue: true })
    end

    def update
      return unless @purchase_order = find_and_check(:purchase_order)

      t3e(@purchase_order.attributes)

      @purchase_order.assign_attributes(permitted_params)

      if @purchase_order.items.all?(&:marked_for_destruction?)
        notify_error_now :purchase_order_need_at_least_one_item
      elsif @purchase_order.save
        return redirect_to(params[:redirect] || { action: :show, id: @purchase_order.id },
                           notify: :record_x_updated,
                           identifier: :number)
      end
      render :edit
    end

    def open
      return unless @purchase_order = find_and_check

      @purchase_order.open
      redirect_to action: :show, id: @purchase_order.id
    end

    def close
      return unless @purchase_order = find_and_check

      @purchase_order.close
      redirect_to action: :show, id: @purchase_order.id
    end
  end
end
