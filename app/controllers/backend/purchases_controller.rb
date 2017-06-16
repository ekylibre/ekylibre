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
    # Displays details of one purchase selected with +params[:id]+
    def show
      return unless @purchase = find_and_check
      respond_with(@purchase, methods: %i[taxes_amount affair_closed],
                              include: { delivery_address: { methods: [:mail_coordinate] },
                                         supplier: { methods: [:picture_path], include: { default_mail_address: { methods: [:mail_coordinate] } } },
                                         parcels: { include: :items },
                                         affair: { methods: [:balance], include: [purchase_payments: { include: :mode }] },
                                         items: { methods: %i[taxes_amount tax_name tax_short_label], include: [:variant] } }) do |format|
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
                  elsif params[:duplicate_of]
                    Purchase.find_by(id: params[:duplicate_of])
                            .deep_clone(include: :items, except: %i[state number affair_id reference_number payment_delay])
                  else
                    Purchase.new(nature: nature)
                  end
      @purchase.currency = @purchase.nature.currency
      @purchase.responsible ||= current_user
      @purchase.planned_at = Time.zone.now
      @purchase.invoiced_at = Time.zone.now
      @purchase.supplier_id ||= params[:supplier_id] if params[:supplier_id]
      if address = Entity.of_company.default_mail_address
        @purchase.delivery_address = address
      end
      render locals: { with_continue: true }
    end

    def create
      item_attributes = permitted_params[:items_attributes] || {}
      safe_params = permitted_params.merge(
        items_attributes: item_attributes.map do |id, item_attr|
          [id, item_attr.except(:asset_exists)]
        end.to_h
      )

      @purchase = resource_model.new(safe_params)
      url = if params[:create_and_continue]
              { action: :new, continue: true, nature_id: @purchase.nature_id }
            else
              params[:redirect] || { action: :show, id: 'id'.c }
            end

      return if save_and_redirect(@purchase, url: url, notify: :record_x_created, identifier: :number)
      render(locals: { cancel_url: { action: :index }, with_continue: true })
    end
  end
end
