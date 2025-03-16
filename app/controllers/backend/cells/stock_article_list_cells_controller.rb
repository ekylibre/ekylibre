module Backend
  module Cells
    class StockArticleListCellsController < Backend::Cells::BaseController
      list(model: :product_nature_variants,
           joins: :category,
           conditions: ["product_nature_variants.active = true AND product_nature_categories.storable = true"],
           order: 'name ASC',
           per_page: 10) do |t|
        t.action :edit, url: { controller: '/backend/product_nature_variants' }
        t.column :number
        t.column :work_number
        t.column :name, url: { namespace: :backend }
        t.column :variety
        t.column :derivative_of
        t.column :current_stock_displayed, label: :current_stock
        t.column :unit_name, label: :unit
      end

      def show; end
    end
  end
end
