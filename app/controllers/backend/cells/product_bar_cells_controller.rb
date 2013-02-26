# -*- coding: utf-8 -*-
class Backend::Cells::ProductBarCellsController < Backend::CellsController

  def show
    data_table = ::GoogleVisualr::DataTable.new
    # Add Column Headers
    data_table.new_column('string', 'Année' )
    data_table.new_column('number', 'Male')
    data_table.new_column('number', 'Femelle')
    # Add Rows and Values
    data_table.add_rows([
      ['2010', 32, 33],
      ['2011', 30, 33],
      ['2012', 35, 28]
    ])
        # set options
    options = { width: 400, height: 240, title: "Product bar chart" }
    # creating the chart
    # @chart = ::GoogleVisualr::Interactive::AreaChart.new(data_table, options)
    @chart = ::GoogleVisualr::Interactive::PieChart.new(data_table, options)
  end

end
