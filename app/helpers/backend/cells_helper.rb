# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier
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
  module CellsHelper
    # No data permit to mark cell as empty
    def no_data
      # content_tag(:div, :no_data.tl, class: 'no-data')
      nil
    end

    def errored
      content_tag(:div, :internal_error.tl, class: 'internal-error')
    end

    # This helper generate a column chart for revenues and expenses
    def evolution_of_revenues_and_expenses_over_time_chart(started_at, stopped_at)
      series = []
      categories = {}
      date = started_at
      while date < stopped_at
        categories[date.year.to_s + date.month.to_s.rjust(3, '0')] = date.l(format: '%b %Y')
        date = date >> 1
      end

      # data for spline sum revenues by month
      all_sale_items = SaleItem.between(started_at, stopped_at)
      item_h = all_sale_items.sums_of_periods.sort.each_with_object({}) do |pair, hash|
        hash[pair.expr.to_i.to_s] = pair.sum.to_d
      end
      series << { type: 'spline', name: :total_sales.tl, data: normalize_serie(item_h, categories.keys), marker: { line_width: 2 } }

      # data for spline sum expenses by month
      all_purchase_items = PurchaseItem.between(started_at, stopped_at)
      item_h = all_purchase_items.sums_of_periods.sort.each_with_object({}) do |pair, hash|
        hash[pair.expr.to_i.to_s] = pair.sum.to_d
      end
      series << { type: 'spline', name: :total_purchases.tl, data: normalize_serie(item_h, categories.keys), marker: { line_width: 2 } }

      # data for incoming_payment by month
      all_incoming_payments_items = IncomingPayment.between(started_at, stopped_at)
      item_h = all_incoming_payments_items.sums_of_periods.sort.each_with_object({}) do |pair, hash|
        hash[pair.expr.to_i.to_s] = pair.sum.to_d
      end
      series << { type: 'spline', name: :incoming_payment_amount.tl, data: normalize_serie(item_h, categories.keys), marker: { line_width: 2 } }

      # Data for outgoing_payments by month
      all_outgoing_payments_items = OutgoingPayment.between(started_at, stopped_at)
      item_h = all_outgoing_payments_items.sums_of_periods.sort.each_with_object({}) do |pair, hash|
        hash[pair.expr.to_i.to_s] = pair.sum.to_d
      end
      series << { type: 'spline', name: :outgoing_payment_amount.tl, data: normalize_serie(item_h, categories.keys), marker: { line_width: 2 } }

      # data for pie revenues by product_nature
      data = []
      sale_items_pretax_amount = all_sale_items.sum(:pretax_amount)
      data << { name: :total_sales.tl, y: sale_items_pretax_amount.to_s.to_f }
      purchases_items_pretax_amount = all_purchase_items.sum(:pretax_amount)
      data << { name: :total_purchases.tl, y: purchases_items_pretax_amount.to_s.to_f }
      incoming_payment_amount = all_incoming_payments_items.sum(:amount)
      data << { name: :incoming_payment_amount.tl, y: incoming_payment_amount.to_s.to_f }
      outgoing_payment_amount = all_outgoing_payments_items.sum(:amount)
      data << { name: :outgoing_payment_amount.tl, y: outgoing_payment_amount.to_s.to_f }

      unless purchases_items_pretax_amount.zero? && sale_items_pretax_amount.zero?
        series << { type: 'pie', name: :total.tl, data: data, center: [50, 50], size: 100, show_in_legend: false, data_labels: { enabled: false } }
      end
      column_highcharts(series, y_axis: { title: { text: :pretax_amount.tl } }, x_axis: { categories: categories.values }, legend: true)
    end
  end
end
