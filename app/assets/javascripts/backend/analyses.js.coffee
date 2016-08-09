((E, $) ->

  $(document).on 'ajax:success', "#analysis-items", (event, item) ->
    items = $(this)
    $(item).children('input').each (_index, input) ->
      if input.id.slice(0, 25) == "analysis_items_attributes" && input.id.slice(-14) == "indicator_name"
        select = $("select[name='indicator_name']")[0]
        $(select.options).each (_ind, option) ->
          if option.value == input.value
            option.setAttribute('hidden', 'true')
            option.setAttribute('disabled', 'true')
            next_option = $(select).find('option:not([disabled])').first()
            console.log next_option
            if next_option.length > 0
              if select.value == input.value
                select.value = next_option.val()
            else
              items.find('.links').hide()

  $(document).on 'cocoon:before-remove', "#analysis-items", (event, item) ->
    items = $(this)
    item.children('input').each (_index, input) ->
      if input.id.slice(0, 25) == "analysis_items_attributes" && input.id.slice(-14) == "indicator_name"
        select = $("select[name='indicator_name']")[0]
        $(select.options).each (_ind, option) ->
          if option.value == input.value
            option.removeAttribute('hidden')
            option.removeAttribute('disabled')
        option = $(select).find('options:not(:disabled)').first()
        links = items.find('.links')
        if option? && links.is(':hidden')
          links.show()


) ekylibre, jQuery
