module Backend
  module Cells
    class TradeCountsCellsController < Backend::Cells::BaseController
      def show
        @unpaid_sales_amount = sales_amount
        @unpaid_purchases_amount = purchases_amount
      end

      private

        def sales_amount
          ApplicationRecord.connection.execute(<<~SQL).first["balance"].to_d
            SELECT abs(sum(distinct_sale_affairs.credit - distinct_sale_affairs.debit)) AS balance
            FROM ( SELECT DISTINCT affairs.*
                   FROM "sales"
                   LEFT JOIN "affairs" ON "affairs"."id" = "sales"."affair_id"
                   WHERE "sales"."state" IN ('order', 'invoice')
                     AND NOT "affairs"."closed"
                 ) AS distinct_sale_affairs
          SQL
        end

        def purchases_amount
          ApplicationRecord.connection.execute(<<~SQL).first["balance"].to_d
            SELECT abs(sum(distinct_purchase_affairs.credit - distinct_purchase_affairs.debit)) AS balance
            FROM ( SELECT DISTINCT affairs.*
                   FROM "purchases"
                   LEFT JOIN "affairs" ON "affairs"."id" = "purchases"."affair_id"
                   WHERE "purchases"."type" = 'PurchaseInvoice'
                     AND NOT "affairs"."closed"
                 ) AS distinct_purchase_affairs
          SQL
        end
    end
  end
end
