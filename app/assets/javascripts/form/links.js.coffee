(($) ->

  setUpdateTriggers = ->
    links = $(this)
    links.each ->
      link = $(this)
      triggerSelector = link.data('update-link-with')
      $(triggerSelector).change ->
        url = link.attr('href')
        triggeredInput = $(this)
        id = triggeredInput.attr 'id'
        value = triggeredInput.val()
        regExp = new RegExp "(\\?|\\&)(#{id})\\=([^&]+)"

        if url.match(regExp)
          url = url.replace(regExp, "$1$2=#{value}")
        else
          if url.indexOf('?') < 0 then url += '?' else url += '&'
          url += "#{id}=#{value}"

        link.attr('href', url)


  $(document).behave 'load', 'a[data-update-link-with]', setUpdateTriggers

  completeUrlWithIds = ->
    links = $(this)
    links.each ->
      link = $(this)
      paramName = $(link).attr('data-complete-link-with-ids')
      checkboxes = $('.list td input[type="checkbox"]')

      $(checkboxes).change ->
        ids = []
        id = parseInt($(this).closest('tr').attr('id').substring(1))
        url = link.attr('href')
        lastUrlParams = ""

        if url.indexOf(paramName) > 0
          idsArray = url.split(paramName)[1]

          if idsArray.indexOf('&') > 0
            index  = idsArray.indexOf('&')
            lastUrlParams = idsArray.substring(index)
            idsArray = idsArray.split('&')[0]

          idsLength = idsArray.length
          idsInLink = idsArray.substring(idsLength - 1, 2)
          ids = JSON.parse("[" + idsInLink + "]")

          paramToSplit = ""

          if url.indexOf("?#{paramName}") > 0 then paramToSplit = '?' else paramToSplit += '&'

          paramToSplit += paramName
          url = url.split("#{paramToSplit}")[0]

        if $(this).is(':checked')
          ids.push(id)
        else
          index = ids.indexOf(id)
          ids.splice(index, 1)

        if url.indexOf('?') < 0 then url += '?' else url += '&'

        url += "#{paramName}=[#{ids.join(', ')}]"
        url += lastUrlParams

        link.attr('href', url)

        if link.attr('data-display-class-on-click')
          elementDisplayOnClick = '.' + link.attr('data-display-class-on-click')

          if ids.length == 0
            $(elementDisplayOnClick).hide()

          if ids.length == 1
            $(elementDisplayOnClick).show()


  $(document).behave 'load', 'a.js-complete-links-with-ids', completeUrlWithIds

  return
) jQuery
