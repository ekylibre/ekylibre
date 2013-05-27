class Backend::Cells::DemoMapCellsController < Backend::CellsController

  def show
    data_table_markers = GoogleVisualr::DataTable.new
    data_table_markers.new_column('string' , 'Ville' )
    data_table_markers.new_column('number' , 'Nombre de ventes')
    data_table_markers.add_rows(4)
    data_table_markers.set_cell(0, 0, 'Paris' )
    data_table_markers.set_cell(0, 1, 400)
    data_table_markers.set_cell(1, 0, 'Nantes' )
    data_table_markers.set_cell(1, 1, 500)
    data_table_markers.set_cell(2, 0, 'Toulouse' )
    data_table_markers.set_cell(2, 1, 600)
    data_table_markers.set_cell(3, 0, 'Bordeaux' )
    data_table_markers.set_cell(3, 1, 700)
     
    opts = { :width => '390', :height => '280', :dataMode => 'markers', :region => 'FR', :colors => ['0xFF8747', '0xFFB581', '0xc06000'] }
    @chart = GoogleVisualr::Interactive::GeoMap.new(data_table_markers, opts)
  end

end
