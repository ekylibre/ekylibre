((E, $) =>
  reduce = (array, reducer, initial) =>
    for element in array
      initial = reducer initial, element
    initial
  filter = (array, predicate) =>
    selected = []
    for element in array
      selected.push element if predicate element
    selected

  filterValidReducer = (elements, rule) =>
    validElements = rule.elements[rule.$watched.val()] || []
    filtered = if validElements.length then filter(elements, ((e) => e.value in validElements)) else []
    if filtered.length
      filtered
    else if rule.emptyBehavior == 'all'
      elements
    else
      []


  class ElementsFilter
    constructor: ($element) ->
      @$element = $element
      @$parent = $element.closest '.control-group'
      @$options = $element.find 'option'
      @rules = $element.data 'filter-rules'
      @onEmpty = $element.data 'filter-on-empty'
      @_enableRules()

    _enableRules: ->
      for rule in @rules
        rule.$watched = $(rule.watch)

        rule.$watched.change =>
          @valueChanged()

    valueChanged: ->
      validOptions = reduce @rules, filterValidReducer, @$options.not('[value=""]')
      @$options.hide()
      $(validOptions).show()
      if validOptions.length
        @$element.val validOptions[0].value
      else
        @$element.find('[value=""]').show()
        @$element.val ''
      if @onEmpty == 'hide' && validOptions.length == 0
        @$parent.hide()
      else
        @$parent.show()

  activateFilter = ($element) =>
    f = new ElementsFilter($element)
    f.valueChanged()

  selector = '[data-filter-rules]'
  E.onDOMElementAdded selector, activateFilter
  $ =>
    $(selector).each -> activateFilter $(@)


  $(document).ready ->
    $('[data-filter-collection]').on 'keyup', ->
      value = $(this).val()
      $selectInput = $($(this).data('filter-collection'))
      url = $selectInput.data('filter-collection-url')

      $.ajax url,
        type: 'GET'
        data: { filter_value: value }

) ekylibre, jQuery
