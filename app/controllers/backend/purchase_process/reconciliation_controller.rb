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

        if params[:reception].present?
          linked_purchase_orders = PurchaseOrder.joins(items: :parcels_purchase_orders_items)
                                                .where('parcel_items.parcel_id' => params[:reception])
                                                .uniq

          opened_purchases_orders = (opened_purchases_orders + linked_purchase_orders).uniq
        end

        items_to_reconcile(opened_purchases_orders)
      end

      def receptions_to_reconciliate
        given_receptions = Reception.with_state(:given)
                                    .joins(:items)
                                    .where(parcel_items: { purchase_invoice_item_id: nil })
                                    .uniq
        if params[:supplier].present?
          given_receptions = given_receptions.where(sender_id: params[:supplier])
        end

        if params[:purchase_invoice].present?
          linked_receptions = Reception.joins(items: :purchase_invoice_item)
                                       .where('purchase_items.purchase_id' => params[:purchase_invoice])
                                       .uniq

          given_receptions = (given_receptions + linked_receptions).uniq
        end
        items_to_reconcile(given_receptions, purchase_orders: false)
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
