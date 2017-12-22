((E, $) ->
  "use strict";

<<<<<<< Updated upstream
  E.wice_grid.settings =
    test: ->
      alert("Yay!")


  $(document).on 'click',
=======

  $(document).ready ->
    # wice-grid-container
    $('.wice-grid-container').each (index, domElement) ->
      wiceGridToolbar = $(domElement).closest('.cobble').find('.wice-grid-toolbar')
      wiceGridTable = $(domElement).find('.wice-grid.table')

  #$(document).on 'click', '.wice-grid-toolbar .wice-grid-columns-selector', ->
  #  alert('Yay!')

  E.wice_grid_settings =

  class Settings
    table: (container) ->
      $(container).find('.wice-grid.table')

    columns: (container) ->
      columns = []
      headers = $(this.table).find('.wice-grid-title-row th')

      headers.each

  WiceGrid.settings = new Settings()
>>>>>>> Stashed changes

  true
) ekylibre, jQuery
