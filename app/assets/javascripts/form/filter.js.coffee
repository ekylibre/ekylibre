((E, $) =>

  activateFilter = ($element) =>
    $controlParent = $element.closest('.control-group')
    elements = $element.data('filter-elements')
    $filterSource = $($element.data('filter-with'))
    return console.error 'Unable to find the source input to use to filter the elements' unless $filterSource.length

    runFilter = () =>
      toActivate = elements[$filterSource.val()] || []
      if toActivate.length
        $controlParent.show()
        $element.find('option').each ->
          if @value in toActivate || @value == '' # Never disable the default option as we select it
            $(@).show()
          else
            $(@).hide()
        # Deselect selected element if disabled. Select the first element of the valid elements instead
        $element.val toActivate[0]
      else
        # No element available to select: Hide control and set empty value
        $controlParent.hide()
        $element.val ''

    $filterSource.change (e) -> runFilter e.target.value
    runFilter()

  selector = '[data-filter-with][data-filter-on][data-filter-elements]'
  E.onDOMElementAdded selector, activateFilter
  $ =>
    $(selector).each -> activateFilter $(@)

) ekylibre, jQuery
