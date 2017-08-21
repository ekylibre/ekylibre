(($, E) ->

  E.links =
    # Adds change event on in order to update a link
    setUpdateTriggers: ->
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

    # Extracts a list of IDs from an URL parameter
    getIdsFromUrl: (url, paramName) ->
      if url.indexOf('?') > 1
        parametersWithValues = url.split('?')[1]
        parametersWithValuesArray = parametersWithValues.split('&')
        for parameterWithValue in parametersWithValuesArray
          name = parameterWithValue.split('=')[0]
          if name == paramName
            parameterValue = parameterWithValue.split('=')[1]
            if parameterValue != ''
              return parameterValue.split(',').map(Number)
      return []


    # Updates IDs list with given un/checked checkbox and existing IDs list
    addOrRemoveIdFromIds: (checkbox, ids, checkboxes) ->
      attrId = checkbox.closest('tr').attr('id')
      if attrId isnt undefined and attrId?
        id = parseInt(attrId.substring(1))
        if checkbox.is(':checked')
          ids.push(id)
        else
          index = ids.indexOf(id)
          ids.splice(index, 1)
      else if checkbox.is('*[data-list-selector="all"]')
        checked = checkbox.is(':checked')
        checkboxes.each ->
          checkbox = $(this)
          attrId = checkbox.closest('tr').attr('id')
          if attrId isnt undefined and attrId?
            id = parseInt(attrId.substring(1))
            if checked
              ids.push(id)
            else
              index = ids.indexOf(id)
              ids.splice(index, 1)
      return ids


    # Updates URL with given IDs
    updateUrlWithIds: (url, ids, paramName) ->
      if url.indexOf(paramName) < 0
        if url.indexOf('?') < 0 then url += '?' else url += '&'
        url += "#{paramName}=#{ids.join(',')}"
      else
        idsArray = url.split(paramName)[1]
        optionalParameters = ""
        if idsArray.indexOf('&') > 0
          indexOptionalParameters = idsArray.indexOf('&')
          optionalParameters = idsArray.substring(index)
          idsArray = idsArray.split('&')[0]

        idsArray = idsArray.substring(1)

        paramToSplit = ""
        if url.indexOf("?#{paramName}") > 0 then paramToSplit = '?' else paramToSplit += '&'
        paramToSplit += paramName
        url = url.split("#{paramToSplit}")[0]

        if url.indexOf('?') < 0 then url += '?' else url += '&'
        url += "#{paramName}=#{ids.join(',')}"
        url += optionalParameters
      return url

    # Adds
    handleShowActions: (link, count) ->
      show_mode = link.data('show-if-checked')
      action_form = link.closest('.action-form')
      if show_mode == 'any'
        if count == 0
          action_form.hide()
        else
          action_form.show()

      else if show_mode == 'two-or-more'
        if count >= 2
          totalDebit = $('#total-debit').text()
          totalCredit = $('#total-credit').text()
          if totalCredit != totalDebit
            action_form.show()
          else
            action_form.hide()
        else
          action_form.hide()



    # Adds
    addEventOnCheckboxes: ->
      links = $(this)
      links.each ->
        link = $(this)
        paramName = link.attr('name')
        checkboxes = $(link.data('complete-link-with-checked-row-ids'))

        checkboxes.change ->
          url = link.attr('href')
          ids = E.links.getIdsFromUrl url, paramName
          ids = E.links.addOrRemoveIdFromIds $(this), ids, checkboxes
          url = E.links.updateUrlWithIds url, ids, paramName
          link.attr('href', url)
          E.links.handleShowActions(link, ids.length)


  $(document).behave 'load', 'a[data-update-link-with]', E.links.setUpdateTriggers

  $(document).behave 'load', 'a[data-complete-link-with-checked-row-ids]', E.links.addEventOnCheckboxes

) jQuery, ekylibre
