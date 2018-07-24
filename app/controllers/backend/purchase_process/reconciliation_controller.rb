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
        opened_purchases_orders = PurchaseOrder.with_state(:opened)
        if params[:supplier].present?
          opened_purchases_orders = opened_purchases_orders.where(supplier: params[:supplier])
        end

        items_to_reconcile(opened_purchases_orders)
      end

      def receptions_to_reconciliate
        receptions = Reception.where(id: ParcelItem.where(purchase_invoice_item_id: nil).map(&:parcel_id),
                                     sender_id: params[:supplier],
                                     state: :given)

        items_to_reconcile(receptions, purchase_orders: false)
      end

      private

      def items_to_reconcile(models, purchase_orders: true)
        render partial: 'backend/purchase_process/reconciliation/items_to_reconcile',
               locals: {
                 models: models,
                 purchase_orders: purchase_orders,
                 reconciliate_item: params[:reconciliate_item],
                 item_field_id: params[:item_field_id]
               }
      end
    end
  end
end
