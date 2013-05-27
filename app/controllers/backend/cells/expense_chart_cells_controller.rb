# -*- coding: utf-8 -*-
class Backend::Cells::ExpenseChartCellsController < Backend::CellsController

  def show
    data_table = ::GoogleVisualr::DataTable.new
    # Add Column Headers
    data_table.new_column('string', "Activités & Familles" )
    data_table.new_column('number', 'Dépenses')
    # Add Rows and Values
    data_table.add_rows(5)
    data_table.set_cell(0, 0, 'Eau & Energie - AUX' )
    data_table.set_cell(0, 1, 11256 )
    data_table.set_cell(1, 0, 'Fermage - AUX' )
    data_table.set_cell(1, 1, 18965 )
    data_table.set_cell(2, 0, 'Administratif - AUX' )
    data_table.set_cell(2, 1, 9865 )
    data_table.set_cell(3, 0, 'Taxes - AUX' )
    data_table.set_cell(3, 1, 14253 )
    data_table.set_cell(4, 0, 'Frais de personnels - AUX' )
    data_table.set_cell(4, 1, 16985 )

        # set options
    options = { width: 330, height: 280, :hAxis => { :title => 'Dépenses liés aux activités auxiliaires'}}
    # creating the chart
    # @chart = ::GoogleVisualr::Interactive::AreaChart.new(data_table, options)
    @chart = ::GoogleVisualr::Interactive::PieChart.new(data_table, options)
  end

end
