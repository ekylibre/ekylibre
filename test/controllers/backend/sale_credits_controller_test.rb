# coding: utf-8

require 'test_helper'
module Backend
  class SaleCreditsControllerTest < ActionController::TestCase
    test_restfully_all_actions new: { credited_sale_id: identify(:sales_001), redirect: '/backend/sales' }, except: :create, fixture_options: { prefix: :sales }
    # , id: SaleItem.where(compute_from: :unit_pretax_amount).select(:sale_id)
    test 'create action' do
      sale = Sale.where(state: :invoice, currency: 'EUR', id: SaleItem.where(compute_from: :unit_pretax_amount).select(:sale_id))
                 .where.not(id: Sale.where.not(credited_sale_id: nil).select(:credited_sale_id))
                 .where.not(affair_id: Affair.where(closed: true))
                 .where.not(affair_id: Regularization.select(:affair_id))
                 .first
      assert sale.present?, 'Cannot find a sales invoice not credited'
      items_attributes = sale.items.each_with_object({}) do |i, h|
        quantity = i.creditable_quantity
        next unless quantity > 0
        h[i.id] = {
          variant_id: i.variant_id,
          compute_from: i.compute_from,
          tax_id: i.tax_id,
          reduction_percentage: i.reduction_percentage,
          credited_item_id: i.id,
          credited_quantity: quantity,
          pretax_amount: -1 * i.pretax_amount,
          amount: -1 * i.amount
        }
        h
      end
      assert items_attributes.any?, 'Cannot test without item to credit'
      c = Sale.count
      post :create, params: {
        sale: {
          client_id: sale.client_id,
          affair_id: sale.affair_id,
          nature_id: sale.nature_id,
          credited_sale_id: sale.id,
          credit: 'true',
          currency: 'EUR',
          items_attributes: items_attributes
        }
      }
      assert c + 1, Sale.count
      assert_response :redirect
      sale_credit = Sale.reorder(:id).last
      assert_equal sale, sale.credited_sale
      refute sale_credit.amount.zero?
    end
  end
end
