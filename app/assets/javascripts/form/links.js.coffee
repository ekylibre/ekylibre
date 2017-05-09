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


  editUrlAndIds = (url, paramName, viewName) ->
    if url.indexOf(paramName) > 0
      ids = []
      idsArray = url.split(paramName)[1]

      if idsArray.indexOf('&') > 0
        index  = idsArray.indexOf('&')
        lastUrlParams = idsArray.substring(index)
        idsArray = idsArray.split('&')[0]

      idsLength = idsArray.length
      if viewName == 'jei-param'
        idsInLink = idsArray.substring(1)
        ids = JSON.parse("[" + idsInLink + "]")
      else if viewName == 'loans-param'
        idsInLink = idsArray.substring(idsLength - 1, 2)
        ids = JSON.parse("[" + idsInLink + "]")

      paramToSplit = ""

      if url.indexOf("?#{paramName}") > 0 then paramToSplit = '?' else paramToSplit += '&'

      paramToSplit += paramName
      url = url.split("#{paramToSplit}")[0]
      return {
        url
        ids
      }

  displayActionButton = (link, viewName, ids) ->
    if link.attr('data-display-class-on-click')
      elementDisplayOnClick = '.' + link.attr('data-display-class-on-click')

      if viewName == 'loans-param'
        if ids.length == 0
          $(elementDisplayOnClick).hide()

        if ids.length == 1
          $(elementDisplayOnClick).show()

      else if viewName == 'jei-param'
        if ids.length <= 1
          $(elementDisplayOnClick).hide()

        if ids.length >= 2
          totalDebit = $('#total-debit').text()
          totalCredit = $('#total-credit').text()
          if totalCredit != totalDebit
            $(elementDisplayOnClick).show()


  completeUrlWithIds = (viewName, links) ->
    links.each ->
      link = $(this)
      paramName = $(link).attr('data-complete-link-with-ids')
      checkboxes = $('.list td input[type="checkbox"]')

      $(checkboxes).change ->
        ids = []
        id = parseInt($(this).closest('tr').attr('id').substring(1))
        url = link.attr('href')
        lastUrlParams = ""

        returnValues = editUrlAndIds url, paramName, viewName
        if returnValues != undefined
          url = returnValues.url
          ids = returnValues.ids

        if $(this).is(':checked')
          ids.push(id)
        else
          index = ids.indexOf(id)
          ids.splice(index, 1)

        if url.indexOf('?') < 0 then url += '?' else url += '&'

        if viewName == 'jei-param'
          url += "#{paramName}=[#{ids.join(', ')}]"
        if viewName == 'loans-param'
          url += "#{paramName}=[#{ids.join(', ')}]"

        url += lastUrlParams

        link.attr('href', url)

        displayActionButton link, viewName, ids


  $(document).behave 'load', 'a.js-complete-links-with-jei-ids', -> 
    completeUrlWithIds 'jei-param', $(this)

  $(document).behave 'load', 'a.js-complete-links-with-loans-ids', -> 
    completeUrlWithIds 'loans-param', $(this)

  return
) jQuery
