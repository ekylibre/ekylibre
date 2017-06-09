(($) ->

  $.setUpdateTriggers = ->
    links = $(this)
    links.each ->
      link = $(this)
      triggerSelector = link.data('update-link-with')
      $(triggerSelector).change ->
        url = link.attr('href')
        triggeredInput = $(this)
        id = triggeredInput.attr 'name'
        value = triggeredInput.val()
        regExp = new RegExp "(\\?|\\&)(#{id})\\=([^&]+)"

        if url.match(regExp)
          url = url.replace(regExp, "$1$2=#{value}")
        else
          if url.indexOf('?') < 0 then url += '?' else url += '&'
          url += "#{id}=#{value}"

        link.attr('href', url)


  $(document).behave 'load', 'a[data-update-link-with]', $.setUpdateTriggers

  $.completeUrlWithIds = ->
    links = $(this)
    links.each ->
      link = $(this)
      paramName = link.attr('name')
      checkboxes = $(link.data('complete-link-with-checked-row-ids'))

      checkboxes.change ->
        url = link.attr('href')
        lastUrlParams = ""
        ids = []

        if url.indexOf(paramName) > 0
          url_ids = url.split(paramName + '=')[1]

          if url_ids? && url_ids.indexOf('&') > 0
            index  = url_ids.indexOf('&')
            lastUrlParams = url_ids.substring(index)
            url_ids = url_ids.split('&')[0]

          if url_ids?
            ids = JSON.parse("[" + url_ids + "]")
          else
            ids = []

          paramToSplit = ""

          if url.indexOf("?#{paramName}") > 0 then paramToSplit = '?' else paramToSplit += '&'

          paramToSplit += paramName
          url = url.split("#{paramToSplit}")[0]

        id = $(this).closest('tr').attr('id')
        if id?
          id = parseInt(id.substring(1))
          if $(this).is(':checked')
            ids.push(id)
          else
            index = ids.indexOf(id)
            ids.splice(index, 1)
        else if $(this).is('*[data-list-selector="all"]')
          checked = $(this).is(':checked')
          checkboxes.each ->
            id = $(this).closest('tr').attr('id')
            if id?
              id = parseInt(id.substring(1))
              if checked
                ids.push(id)
              else
                index = ids.indexOf(id)
                ids.splice(index, 1)

        if url.indexOf('?') < 0 then url += '?' else url += '&'

        url += "#{paramName}=#{ids.join(',')}"
        url += lastUrlParams

        link.attr('href', url)

        action_form = link.closest('.action-form')
        if !action_form? && link.data('display-if-any-checked')
          action_form = $(link.data('display-if-any-checked'))
        if action_form?
          if ids.length == 0
            action_form.hide()
          else
            action_form.show()


  $(document).behave 'load', 'a[data-complete-link-with-checked-row-ids]', $.completeUrlWithIds

  return
) jQuery
