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
                     except: :new, continue: [:nature_id]

    unroll :number, :reference_number, :ordered_at, :pretax_amount, supplier: :full_name

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
      t.column :pretax_amount, currency: true, on_select: :sum, hidden: true
    end

    list(:items, model: :purchase_items, order: { id: :asc }, conditions: { purchase_id: 'params[:id]'.c }) do |t|
      t.column :variant, url: true
      t.column :annotation
      t.column :first_reception_number, label: :reception, url: { controller: '/backend/receptions', id: 'RECORD.first_reception_id'.c }
      t.column :quantity
      t.column :human_received_quantity, label: :received_quantity, datatype: :decimal
      t.column :quantity_to_receive, label: :quantity_to_receive, datatype: :decimal
      t.column :unit_pretax_amount, currency: true
      t.column :unit_amount, currency: true, hidden: true
      t.column :reduction_percentage
      t.column :tax, url: true, hidden: true
      t.column :pretax_amount, currency: true
      t.column :amount, currency: true, hidden: :true
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
          filename = "Bon_de_commande_#{@purchase_order.reference_number}"
          @dataset_purchase_order = @purchase_order.order_reporting
          send_data to_odt(@dataset_purchase_order, filename, params).generate, type: 'application/vnd.oasis.opendocument.text', disposition: 'attachment', filename: filename << '.odt'
        end
        format.pdf do
          to_pdf
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
      if address = Entity.of_company.default_mail_address
        @purchase_order.delivery_address = address
      end
      render locals: { with_continue: true }
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

    protected

    def to_pdf
      filename = "Bon_de_commande_#{@purchase_order.reference_number}"
      @dataset_purchase_order = @purchase_order.order_reporting
      file_odt = to_odt(@dataset_purchase_order, filename, params).generate
      tmp_dir = Ekylibre::Tenant.private_directory.join('tmp')
      uuid = SecureRandom.uuid
      source = tmp_dir.join(uuid + '.odt')
      dest = tmp_dir.join(uuid + '.pdf')
      FileUtils.mkdir_p tmp_dir
      File.write source, file_odt
      `soffice  --headless --convert-to pdf --outdir #{Shellwords.escape(tmp_dir.to_s)} #{Shellwords.escape(source)}`
      send_data(File.read(dest), type: 'application/pdf', disposition: 'attachment', filename: filename + '.pdf')
    end

    def to_odt(order_reporting, filename, _params)
      # TODO: add a generic template system path
      report = ODFReport::Report.new(Rails.root.join('config', 'locales', 'fra', 'reporting', 'purchase_order.odt')) do |r|
        # TODO: add a helper with generic metod to implemend header and footer

        e = Entity.of_company
        company_name = e.full_name
        company_address = e.default_mail_address.present? ? e.default_mail_address.coordinate : '-'
        company_phone = e.phones.present? ? e.phones.first.coordinate : '-'
        company_email = order_reporting[:purchase_responsible_email]

        r.add_field 'COMPANY_ADDRESS', company_address
        r.add_field 'COMPANY_NAME', company_name
        r.add_field 'COMPANY_PHONE', company_phone
        r.add_field 'COMPANY_EMAIL', company_email
        r.add_field 'FILENAME', filename
        r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')

        r.add_field 'PURCHASE_NUMBER', order_reporting[:purchase_number]
        r.add_field 'PURCHASE_ORDERED_AT', order_reporting[:purchase_ordered_at]
        r.add_field 'PURCHASE_ESTIMATE_RECEPTION_DATE', order_reporting[:purchase_estimate_reception_date]
        r.add_field 'PURCHASE_RESPONSIBLE', order_reporting[:purchase_responsible]
        r.add_field 'SUPPLIER_NAME', order_reporting[:supplier_name]
        r.add_field 'SUPPLIER_PHONE', order_reporting[:supplier_phone]
        r.add_field 'SUPPLIER_MOBILE_PHONE', order_reporting[:supplier_mobile_phone]
        r.add_field 'SUPPLIER_ADDRESS', order_reporting[:supplier_address]
        r.add_field 'SUPPLIER_EMAIL', order_reporting[:supplier_email]
        r.add_image :company_logo, order_reporting[:entity_picture]

        r.add_table('P_ITEMS', order_reporting[:items], header: true) do |t|
          t.add_column(:variant)
          t.add_column(:quantity)
          t.add_column(:unity)
          t.add_column(:unit_pretax_amount)
          t.add_column(:pretax_amount)
        end

        r.add_field 'PURCHASE_PRETAX_AMOUNT', order_reporting[:purchase_pretax_amount]
        r.add_field 'PURCHASE_CURRENCY', order_reporting[:purchase_currency]
      end
    end
  end
end
