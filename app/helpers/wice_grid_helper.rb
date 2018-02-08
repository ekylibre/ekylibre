module WiceGridHelper
  def list_settings_toolbar(menu_up: false)
    toolbar_classes = ''
    toolbar_classes << 'menu-up' if menu_up

    render partial: '/backend/shared/wice_grid/list_settings', locals: { toolbar_classes: toolbar_classes }
  end
end
