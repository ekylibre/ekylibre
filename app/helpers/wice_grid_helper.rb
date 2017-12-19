module WiceGridHelper
  def list_settings_toolbar(columns: {})
    render partial: "/backend/shared/wice_grid/list_settings", locals: { columns: columns }
  end
end
