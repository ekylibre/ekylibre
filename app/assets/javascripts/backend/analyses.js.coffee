((E, $) ->

  $(document).on 'ajax:success', "*", (event, item) ->
    $(item).children('input').each (_index, input) ->
      if input.id.slice(0, 25) == "analysis_items_attributes" && input.id.slice(-14) == "indicator_name"
        select = $("select[name='indicator_name']")[0]
        $(select.options).each (_ind, option) ->
          if option.value == input.value
            option.setAttribute('hidden', 'true')
            option.setAttribute('disabled', 'true')
            if select.value == input.value
              select.value = ""

  $(document).on 'cocoon:before-remove', "*", (event, item) ->
    item.children('input').each (_index, input) ->
      if input.id.slice(0, 25) == "analysis_items_attributes" && input.id.slice(-14) == "indicator_name"
        select = $("select[name='indicator_name']")[0]
        $(select.options).each (_ind, option) ->
          if option.value == input.value
            option.removeAttribute('hidden')
            option.removeAttribute('disabled')


) ekylibre, jQuery
