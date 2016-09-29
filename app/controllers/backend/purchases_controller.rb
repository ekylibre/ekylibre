# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
  class PurchasesController < Backend::BaseController
    manage_restfully planned_at: 'Time.zone.today+2'.c, redirect_to: '{action: :show, id: "id".c}'.c, except: :new

    respond_to :csv, :ods, :xlsx, :pdf, :odt, :docx, :html, :xml, :json

    unroll :number, :amount, :currency, :created_at, supplier: :full_name

    # params:
    #   :q Text search
    #   :state State search
    #   :period Two dates with "_" separator
    def self.purchases_conditions
      code = ''
      code = search_conditions(purchases: [:created_at, :pretax_amount, :amount, :number, :reference_number, :description, :state], entities: [:number, :full_name]) + " ||= []\n"
      code << "if params[:period].present? && params[:period].to_s != 'all'\n"
      code << "  c[0] << ' AND #{Purchase.table_name}.invoiced_at BETWEEN ? AND ?'\n"
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
      code << "  c[0] << ' AND #{Purchase.table_name}.state IN (?)'\n"
      code << "  c << params[:state]\n"
      code << "end\n "
      code << "if params[:nature].present? && params[:nature].to_s != 'all'\n"
      code << "  if params[:nature] == 'unpaid'\n"
      code << "    c[0] << ' AND NOT #{Affair.table_name}.closed'\n"
      code << "  end\n"
      code << "end\n"
      code << "if params[:responsible_id].to_i > 0\n"
      code << "  c[0] += ' AND #{Purchase.table_name}.responsible_id = ?'\n"
      code << "  c << params[:responsible_id]\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    list(conditions: purchases_conditions, joins: [:supplier, :affair], line_class: :status, order: { created_at: :desc, number: :desc }) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :reference_number, url: true
      t.column :created_at
      t.column :planned_at, hidden: true
      t.column :invoiced_at
      t.column :supplier, url: true
      t.column :supplier_address, hidden: true
      t.column :description
      # t.column :shipped
      t.status
      t.column :state_label
      # t.column :paid_amount, currency: true
      t.column :pretax_amount, currency: true
      t.column :amount, currency: true
    end

    list(:items, model: :purchase_items, conditions: { purchase_id: 'params[:id]'.c }) do |t|
      # t.action :new, on: :none, url: {purchase_id: 'params[:id]'.c}, if: :draft?
      # t.action :edit, if: :draft?
      # t.action :destroy, if: :draft?
      t.column :variant, url: true
      t.column :annotation
      t.column :quantity
      t.column :unit_pretax_amount, currency: true
      t.column :unit_amount, currency: true, hidden: true
      t.column :reduction_percentage
      t.column :pretax_amount, currency: true
      t.column :amount, currency: true
      t.column :activity_budget, hidden: true
      t.column :team, hidden: true
    end

    list(:parcels, model: :parcels, children: :items, conditions: { purchase_id: 'params[:id]'.c }) do |t|
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

    # Displays details of one purchase selected with +params[:id]+
    def show
      return unless @purchase = find_and_check
      respond_with(@purchase, methods: [:taxes_amount, :affair_closed],
                              include: { delivery_address: { methods: [:mail_coordinate] },
                                         supplier: { methods: [:picture_path], include: { default_mail_address: { methods: [:mail_coordinate] } } },
                                         parcels: { include: :items },
                                         affair: { methods: [:balance], include: [outgoing_payments: { include: :mode }] },
                                         items: { methods: [:taxes_amount, :tax_name, :tax_short_label], include: [:variant] } }) do |format|
        format.html do
          t3e @purchase.attributes, supplier: @purchase.supplier.full_name, state: @purchase.state_label, label: @purchase.label
        end
      end
    end

    def new
      unless nature = PurchaseNature.find_by(id: params[:nature_id]) || PurchaseNature.by_default
        notify_error :need_a_valid_purchase_nature_to_start_new_purchase
        redirect_to action: :index
        return
      end
      @purchase = if params[:intervention_ids]
                    Intervention.convert_to_purchase(params[:intervention_ids])
                  else
                    Purchase.new(nature: nature)
                  end
      @purchase.currency = @purchase.nature.currency
      @purchase.responsible = current_user
      @purchase.planned_at = Time.zone.now
      @purchase.invoiced_at = Time.zone.now
      @purchase.supplier_id ||= params[:supplier_id] if params[:supplier_id]
      if address = Entity.of_company.default_mail_address
        @purchase.delivery_address = address
      end
    end

    def abort
      return unless @purchase = find_and_check
      @purchase.abort
      redirect_to action: :show, id: @purchase.id
    end

    def confirm
      return unless @purchase = find_and_check
      @purchase.confirm
      redirect_to action: :show, id: @purchase.id
    end

    def correct
      return unless @purchase = find_and_check
      @purchase.correct
      redirect_to action: :show, id: @purchase.id
    end

    def invoice
      return unless @purchase = find_and_check
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @purchase.invoice(params[:invoiced_at])
      end
      redirect_to action: :show, id: @purchase.id
    end

    def propose
      return unless @purchase = find_and_check
      @purchase.propose
      redirect_to action: :show, id: @purchase.id
    end

    def propose_and_invoice
      return unless @purchase = find_and_check
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @purchase.propose
        raise ActiveRecord::Rollback unless @purchase.confirm
        # raise ActiveRecord::Rollback unless @purchase.deliver
        raise ActiveRecord::Rollback unless @purchase.invoice
      end
      redirect_to action: :show, id: @purchase.id
    end

    def refuse
      return unless @purchase = find_and_check
      @purchase.refuse
      redirect_to action: :show, id: @purchase.id
    end
  end
end
