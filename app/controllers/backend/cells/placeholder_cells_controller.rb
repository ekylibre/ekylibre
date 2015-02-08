class Backend::Cells::PlaceholderCellsController < Backend::Cells::BaseController

  def show
    @count = rand(4)+1
    data_table = GoogleVisualr::DataTable.new
    # Add Column Headers
    data_table.new_column('string', 'Annee' )
    data_table.new_column('number', 'Male')
    data_table.new_column('number', 'Femelle')
    # Add Rows and Values
    data_table.add_rows([
      ['2010', 32, 33],
      ['2011', 30, 33],
      ['2012', 35, 28]
    ])
        # set options
    option = { width: 400, height: 240, title: "Titre" }
    # creating the chart
    #@chart = GoogleVisualr::Interactive::AreaChart.new(data_table, option)
    @chart = GoogleVisualr::Interactive::PieChart.new(data_table, option)
  end

end
