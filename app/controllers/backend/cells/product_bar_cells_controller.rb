# -*- coding: utf-8 -*-
class Backend::Cells::ProductBarCellsController < Backend::CellsController

  def show
    data_table = ::GoogleVisualr::DataTable.new
    # Add Column Headers
    data_table.new_column('string', 'Année' )
    data_table.new_column('number', 'Male')
    data_table.new_column('number', 'Femelle')
    # Add Rows and Values

    for year in (Date.today.year-3)..Date.today.year
      animals = Animal.where("EXTRACT(year from born_at) = ?", year)
      data_table.add_rows([[year.to_s, animals.where(:sex => "male").count, animals.where(:sex => "female").count]])
    end

        # set options
    options = { :legend => {position: 'bottom', textStyle: {color: 'blue', fontSize: 10}} , width: 250, height: 280, :hAxis => { :title => 'Année'}, :vAxis => { :title => 'Nombre de naissance'}}
    # creating the chart
    # @chart = ::GoogleVisualr::Interactive::AreaChart.new(data_table, options)
    @chart = ::GoogleVisualr::Interactive::ColumnChart.new(data_table, options)
  end

end
