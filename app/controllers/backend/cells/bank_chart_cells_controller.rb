# -*- coding: utf-8 -*-
class Backend::Cells::BankChartCellsController < Backend::CellsController

  def show
    data_table = ::GoogleVisualr::DataTable.new
    # Add Column Headers
    data_table.new_column('string', 'Mois' )
    data_table.new_column('number', 'Recettes')
    data_table.new_column('number', 'Dépenses')
    # Add Rows and Values
     data_table.add_rows(4)
      data_table.set_cell(0, 0, '2010')
      data_table.set_cell(0, 1, 121000)
      data_table.set_cell(0, 2, 84400)
      data_table.set_cell(1, 0, '2011')
      data_table.set_cell(1, 1, 111170)
      data_table.set_cell(1, 2, 92460)
      data_table.set_cell(2, 0, '2012')
      data_table.set_cell(2, 1, 125660)
      data_table.set_cell(2, 2, 98120)
      data_table.set_cell(3, 0, '2013')
      data_table.set_cell(3, 1, 60030)
      data_table.set_cell(3, 2, 45540)

        # set options
    options = { width: 330, height: 280, :hAxis => { :title => 'Trésorerie'}}
    # creating the chart
    # @chart = ::GoogleVisualr::Interactive::AreaChart.new(data_table, options)
    @chart = ::GoogleVisualr::Interactive::BarChart.new(data_table, options)
  end

end
