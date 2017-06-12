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
  class PurchaseOrdersController < Backend::PurchasesController
    manage_restfully planned_at: 'Time.zone.today+2'.c, redirect_to: '{action: :show, id: "id".c}'.c,
                     except: :new, continue: [:nature_id]

    unroll :number, :amount, :currency, :created_at, supplier: :full_name

    def self.list_conditions
      code = ''
      code = search_conditions(purchase_order: %i[number reference_number supplier created_at pretax_amount], entities: %i[number full_name]) + " ||= []\n"
      code << "if params[:period].present? && params[:period].to_s != 'all'\n"
      code << "  c[0] << ' AND #{PurchaseOrder.table_name}.invoiced_at::DATE BETWEEN ? AND ?'\n"
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
      t.column :supplier, url: true
      t.column :created_at
      t.column :pretax_amount, currency: true, on_select: :sum, hidden: true
    end

    list(:items, model: :purchase_items, order: { id: :asc }, conditions: { purchase_id: 'params[:id]'.c }) do |t|
      t.column :variant, url: true
      t.column :annotation
      t.column :quantity
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

    def show
      return unless @purchase_order = find_and_check
      respond_with(@purchase_order, methods: [:taxes_amount],
                                    include: { delivery_address: { methods: [:mail_coordinate] },
                                               supplier: { methods: [:pictures_path], include: { default_mail_address: { methods: [:mail_coordinate] } } },
                                               parcels: { include: [:items] },
                                               items: { methods: %i[taxes_amount tax_name tax_short_label], include: [:variant] } }) do |format|
        format.html do
          t3e @purchase_order.attributes, supplier: @purchase_order.supplier.full_name, state: @purchase_order.state_label, label: @purchase_order.label
        end
      end
    end

    def open
      return unless @purchase_order = find_and_check
      @purchase_order.open
      redirect_to action: :show, id: @purchase_order.id
    end
  end
end
