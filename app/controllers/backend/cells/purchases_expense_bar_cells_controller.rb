# -*- coding: utf-8 -*-
class Backend::Cells::PurchasesExpenseBarCellsController < Backend::CellsController

  def show
    data_table = ::GoogleVisualr::DataTable.new
    # Add Column Headers
    data_table.new_column('string', 'Mois' )
    data_table.new_column('number', 'Dépenses')
    # Add Rows and Values

    for month in (Date.today.month-6)..Date.today.month
      purchases = Purchase.where("EXTRACT(month from created_on) = ?", month)
      data_table.add_rows([[month.to_s, purchases.where(:state => "order").sum(:pretax_amount)]])
    end

        # set options
    options = { :legend => {position: 'top'}, width: 300, height: 250, :hAxis => { :title => "Dépenses HT par mois"}}
    # creating the chart
    # @chart = ::GoogleVisualr::Interactive::AreaChart.new(data_table, options)
    @chart = ::GoogleVisualr::Interactive::ColumnChart.new(data_table, options)
  end

end
