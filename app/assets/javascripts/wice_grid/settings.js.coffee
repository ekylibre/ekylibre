((E, $) ->
  "use strict";

  $(document).ready ->
    $('.wice-grid-container').each (index, domElement) ->
      E.wice_grid_settings.addColumnsToToolbar(domElement)

  $(document).on 'mouseover', '.wice-grid-toolbar .parent', ->
    E.wice_grid_settings.setToolbarUp($(this))

  $(document).on 'click', '.wice-grid-toolbar .parent', ->
    if $(this).hasClass('checked')
      $(this).addClass('unchecked')
      $(this).removeClass('checked')

      $('thead #' + $(this).data('corresponding-column')).addClass('hidden')
      $('tbody #' + $(this).data('corresponding-column')).addClass('hidden')
    else
      $(this).addClass('checked')
      $(this).removeClass('unchecked')

      $('thead #' + $(this).data('corresponding-column')).removeClass('hidden')
      $('tbody #' + $(this).data('corresponding-column')).removeClass('hidden')


  class Settings
    setToolbarUp: (container) ->
      toolbar = this.toolbar(container)

      if $(toolbar).hasClass('menu-up')
        dropdownColumnsMenu = this.toolbar(container).find('.dropdown-columns-menu')
        dropdownHeight = $(dropdownColumnsMenu).height()

        $(dropdownColumnsMenu).attr('style', 'top: -' + dropdownHeight + "px;")

    toolbar: (container) ->
      $(container).closest('.cobble').find('.wice-grid-toolbar')

    table: (container) ->
      $(container).find('.wice-grid.table')

    columns: (container) ->
      this.table(container).find('.wice-grid-title-row th')

    addColumnsToToolbar: (container) ->
      self = this
      this.columns(container).each (index, column) ->
        newLine = $(document.createElement('A'))
        newLine.append('<i></i>')
        newLine.append('<span>' + $(column).text() + '</span>')

        checkedColumn = 'checked'
        if $(column).hasClass('hidden')
          checkedColumn = 'unchecked'

        newColumnLine = $(document.createElement('LI'))
        newColumnLine.addClass('wice-grid-columns-selector ' + checkedColumn)
        newColumnLine.attr('data-corresponding-column', $(column).attr('id'))
        newColumnLine.append(newLine)

        self.toolbar(container).find('.dropdown-columns-menu').append(newColumnLine)


  E.wice_grid_settings = new Settings()

  true
) ekylibre, jQuery
