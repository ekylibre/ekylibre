((E, $) ->
  "use strict";

  $(document).ready ->
    # wice-grid-container
    $('.wice-grid-container').each (index, domElement) ->
      #wiceGridToolbar = WiceGrid.settings.toolbar(domElement)
      #wiceGridTable = WiceGrid.settings.table(domElement)
      E.wice_grid_settings.addColumnsToToolbar(domElement)

  $(document).on 'click', '.wice-grid-toolbar .wice-grid-columns-selector', ->
    alert('Yay!')

#  E.wice_grid_settings =

  class Settings
    toolbar: (container) ->
      $(container).closest('.cobble').find('.wice-grid-toolbar')

    table: (container) ->
      $(container).find('.wice-grid.table')

    columns: (container) ->
      this.table(container).find('.wice-grid-title-row th')

    addColumnsToToolbar: (container) ->
      self = this
      this.columns(container).each (index, column) ->
        newColumnLine = $(document.createElement('LI'))
        newColumnLine.text($(column).text())

        self.toolbar(container).find('.dropdown-columns-menu').append(newColumnLine)


  E.wice_grid_settings = new Settings()

  true
) ekylibre, jQuery
