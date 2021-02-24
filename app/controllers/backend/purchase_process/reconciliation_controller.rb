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
  module PurchaseProcess
    class ReconciliationController < Backend::BaseController
      def purchase_orders_to_reconciliate
        return items_to_reconcile(:purchase_orders, []) if params[:supplier].blank?

        orders = if params[:reception].present?
                   PurchaseOrder.joins('INNER JOIN purchase_items ON purchase_items.purchase_id = purchases.id LEFT JOIN parcel_items ON parcel_items.purchase_order_item_id = purchase_items.id')
                                .where('purchases.state = ? AND purchases.supplier_id = ? OR parcel_items.parcel_id = ?', :opened, params[:supplier], params[:reception])
                                .distinct
                 else
                   PurchaseOrder.with_state(:opened)
                                .where(supplier: params[:supplier])
                 end

        items_to_reconcile(:purchase_orders, orders.order(:ordered_at))
      end

      def receptions_to_reconciliate
        return items_to_reconcile(:receptions, []) if params[:supplier].blank?

        receptions = if params[:purchase_invoice].present?
                       Reception.with_state(:given)
                                .joins('INNER JOIN parcel_items ON parcel_items.parcel_id = parcels.id LEFT JOIN purchase_items ON purchase_items.id = parcel_items.purchase_invoice_item_id')
                                .where('parcel_items.purchase_invoice_item_id IS NULL AND parcels.sender_id = ? OR purchase_items.purchase_id = ?', params[:supplier], params[:purchase_invoice])
                                .distinct
                     else
                       Reception.with_state(:given)
                                .joins(:items)
                                .where(parcel_items: { purchase_invoice_item_id: nil }, sender_id: params[:supplier])
                                .distinct
                     end

        items_to_reconcile(:receptions, receptions.order(:given_at))
      end

      private

        def items_to_reconcile(model_name, items)
          render partial: "backend/purchase_process/reconciliation/#{model_name}_to_reconcile",
                 locals: {
                   items: items,
                   item_field_id: params[:item_field_id]
                 }
        end
    end
  end
end
