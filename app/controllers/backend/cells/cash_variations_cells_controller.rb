module Backend
  module Cells
    class CashVariationsCellsController < Backend::Cells::BaseController
      include ChartsHelper

      def show
        stopped_at = Time.zone.today.end_of_month
        started_at = stopped_at + 1.day - 1.year
        @series = []
        @categories = first_day_of_months_between(started_at, stopped_at)

        all_outgoing_payments = OutgoingPayment.between started_at, stopped_at
        @series << create_serie_for(all_outgoing_payments, @categories, :total_expenses)

        all_incoming_payments = IncomingPayment.between started_at, stopped_at
        @series << create_serie_for(all_incoming_payments, @categories, :total_revenues)

        all_payslip_payments = PayslipPayment.between started_at, stopped_at
        @series << create_serie_for(all_payslip_payments, @categories, :salary_payments)
      end

      private

        def create_serie_for(collection, categories, name)
          grouped_collection = collection.group_by { |item| item.paid_at.beginning_of_month.to_date }
          data = grouped_collection.map { |k, v| [k, v.sum(&:amount)] }.sort.to_h
          chart_data = fill_values categories, data, empty_value: 0.0

          { type: 'spline', name: name.tl, data: chart_data, marker: { line_width: 2 } }
        end

        def first_day_of_months_between(started_at, stopped_at)
          res = started_at
          categories = []

          while res < stopped_at do
            categories << res
            res += 1.month
          end

          categories
        end

        def fill_values(categories, values, empty_value:)
          categories.map do |date|
            values.fetch(date, empty_value).to_f
          end
        end
    end
  end
end