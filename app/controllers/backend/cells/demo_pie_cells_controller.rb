class Backend::Cells::DemoPieCellsController < Backend::CellsController

  def show
    data_table = ::GoogleVisualr::DataTable.new
    # Add Column Headers
    data_table.new_column('string', 'Nom du type de produit' )
    data_table.new_column('number', 'CA')
    # Add Rows and Values
    data_table.add_rows(5)
    data_table.set_cell(0, 0, 'Lait' )
    data_table.set_cell(0, 1, 11 )
    data_table.set_cell(1, 0, 'Veau' )
    data_table.set_cell(1, 1, 2 )
    data_table.set_cell(2, 0, 'Vache' )
    data_table.set_cell(2, 1, 2 )
    data_table.set_cell(3, 0, 'Taurillon' )
    data_table.set_cell(3, 1, 2 )
    data_table.set_cell(4, 0, 'Autres' )
    data_table.set_cell(4, 1, 7 )
    
        # set options
    options = { width: 390, height: 280}
    # creating the chart
    # @chart = ::GoogleVisualr::Interactive::AreaChart.new(data_table, options)
    @chart = ::GoogleVisualr::Interactive::PieChart.new(data_table, options)
  end

end
