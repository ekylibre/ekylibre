((E, $) ->
  "use strict"

  E.bankReconciliation = null

  $ ->
    precision = parseInt($(".reconciliation-list").data('currency-precision'))
    E.bankReconciliation = new BankReconciliation(precision)

    E.bankReconciliation.initialize()

    position_space = new RegExp(".*scroll_to=(\\d+).*")
    position = position_space.exec location.search
    if position
      scrollTo = $("[data-type=bank_statement_item][data-id=#{position[1]}]").parents('.date-section')[0]
      $('.list').scrollTop(scrollTo.offsetTop - $('.list')[0].offsetTop)

  $(document).on "click", ".reconciliation-item[data-type=bank_statement_item] a#delete", ->
    # Remove bank statement item
    button = $(@)
    bankStatementItem = E.bankReconciliation.closestLine(button)
    E.bankReconciliation.destroyLine bankStatementItem
    return false

  $(document).on "click", ".reconciliation-item:not(.selected)", (event) ->
    # Select line
    return if $(event.target).is("input,a,form")
    E.bankReconciliation.selectLine $(@)

  $(document).on "click", ".reconciliation-item.selected", (event) ->
    # Deselect line
    return if $(event.target).is("input,a")
    E.bankReconciliation.deselectLine $(@)

  $(document).on "click", ".reconciliation-item a#clear", (event) ->
    # Clear reconciliation letter
    event.stopPropagation();
    button = $(@)
    line = E.bankReconciliation.closestLine(button)
    E.bankReconciliation.clearReconciliationLetterFromLine line
    return false

  $(document).on "click", ".reconciliation-item[data-type=journal_entry_item] a#complete", ->
    # Complete journal entry items
    button = $(@)
    line = E.bankReconciliation.closestLine(button)
    E.bankReconciliation.completeJournalEntryItems line
    return false

  $(document).on "confirm:complete", "#reset_reconciliation", (e, response) ->
    if response
      E.bankReconciliation.clearAllReconciliationLetters()

  $(document).on "click", "#auto_reconciliation", ->
    # Automatic reconciliation
    E.bankReconciliation.autoReconciliate()

  $(document).on "change", "#hide-lettered", ->
    E.bankReconciliation.uiUpdate()

  $(document).on "change", "#set_period", (event) ->
    matches = event.target.value.match(/\d+-\d+-\d+/g)
    if matches.length != 2
      return

    start = moment(matches[0]).format('YYYY-MM-DD')
    end = moment(matches[1]).format('YYYY-MM-DD')

    url = new URL(location.href)
    url.searchParams.set('period_start', start)
    url.searchParams.set('period_end', end)

    urlStr = url.toString()

    if location.href != urlStr
      location.href = urlStr


  class BankReconciliation
    constructor: (@precision) ->

    initialize: ->
      @uiUpdate()

    # Accessors

    closestLine: (element) ->
      element.closest @_lines()

    ## NEW BANK STATEMENT ITEMS

    # Add bank statement items

    createBankStatementItem: (date) ->
      return if @_addBankStatementItemInDateSection(date)
      #@_insertDateSection date
      @_addBankStatementItemInDateSection date

    _addBankStatementItemInDateSection: (date) ->
      formatedDate = moment(date).format("YYYY-MM-DD")
      dateSection = $("p[data-date=#{formatedDate}]").closest('.date-section')
      dateSection.removeClass('hidden')
      newItemButton = dateSection.children(".date-header").find('a')
      return false unless newItemButton.length
      newItemButton.click()
      true

    _insertDateSection: (date) ->
      template = $($(".date-header p[data-date=tmpl-date]")[0]).parents(".date-section")[0].outerHTML
      html = template.replace(/tmpl-date/g, date)
      html = $(html).removeClass('hidden')[0].outerHTML
      dateSections = $(".date-header p[data-date!=tmpl-date]")
      nextDateSection = dateSections.filter(-> $(@).data("date") > date).first()
      if nextDateSection.length
        nextDateSection.parent(".date-section").before html
      else
        $(".reconciliation-list .totals").before html

    # Add bank statement items from selected journal entry items

    completeJournalEntryItems: (clickedLine) ->
      params =
        name: clickedLine.find('.name').first().html()

      selectedJournalEntryItems = @_lines().filter("[data-type=journal_entry_item].selected")
      debit = selectedJournalEntryItems.find(".debit").sum()
      credit = selectedJournalEntryItems.find(".credit").sum()
      balance = debit - credit
      if balance > 0
        params.credit = balance
      else
        params.debit = -balance

      date = @_dateForLine(clickedLine)
      buttonInDateSection = $(".date-header p[data-date=#{date}]").parent(".date-header").find('a')
      buttonInDateSection.one "ajax:beforeSend", (event, xhr, settings) ->
        for key,value of params
          settings.url += "&bank_statement_item[#{key}]=#{value}"
      buttonInDateSection.one "ajax:complete", (event, xhr, status) =>
        # use ajax:complete to ensure elements are already added to the DOM
        return unless status is "success"
        @uiUpdate()
      buttonInDateSection.click()

    # Remove bank statement items

    destroyLine: (line) ->
      if line.data('id')? then @_deleteLine(line) else @_destroyBankStatementItem(line);

    _destroyBankStatementItem: (bankStatementItem) ->
      @_removeLine bankStatementItem
      @_clearLinesWithReconciliationLetter @_reconciliationLetter(bankStatementItem)
      @_reconciliateSelectedLinesIfValid()
      @uiUpdate()

    _removeLine: (line) ->
      form = line.parents('form')
      parent = line.parents('.date-section')
      siblings = parent.find('.reconciliation-item')
      line.deepRemove()
      form.deepRemove() if form?
      if siblings.length <= 1
        parent.addClass('hidden')

    _isDateSection: (line) ->
      line.hasClass("date-header")

    # Select/deselect lines

    selectLine: (line) ->
      return if @_isLineReconciliated(line) or isNaN(@_idForLine(line)) or @_isLineLocked(line)
      line.addClass "selected"
      @_reconciliateSelectedLinesIfValid()
      @uiUpdate()

    deselectLine: (line) ->
      line.removeClass "selected"
      @_reconciliateSelectedLinesIfValid()
      @uiUpdate()

    # Reconciliation methods

    clearAllReconciliationLetters: ->
      letters = []
      @_reconciliatedLines().each (i, e) =>
        letter = @_reconciliationLetter($(e))
        letters.push(letter) unless letters.includes(letter)
      @_clearLinesWithReconciliationLetter(letter) for letter in letters
      @uiUpdate()

    clearReconciliationLetterFromLine: (line) ->
      letter = @_reconciliationLetter(line)
      return unless letter
      @_clearLinesWithReconciliationLetter letter
      @uiUpdate()

    autoReconciliate: ->
      notReconciliated = @_notReconciliatedLines()
      bankItems = notReconciliated.filter("[data-type=bank_statement_item]")
      journalItems = notReconciliated.filter("[data-type=journal_entry_item]")

      bankItems.each (i, e) =>
        date = @_dateForLine($(e))
        credit = @_creditForLine($(e))
        debit = @_debitForLine($(e))
        similarBankItems = @_filterLinesBy(bankItems, date: date, credit: credit, debit: debit)
        return if similarBankItems.length isnt 1
        similarJournalItems = @_filterLinesBy(journalItems, date: date, credit: debit, debit: credit)
        return if similarJournalItems.length isnt 1
        @_letterItems $(e).add(similarJournalItems)
      @uiUpdate()

    _reconciliateSelectedLinesIfValid: ->
      selected = @_lines().filter(".selected")
      return unless @_areLineValidForReconciliation(selected)
      @_letterItems selected

    _areLineValidForReconciliation: (lines) ->
      return false unless lines.length
      journalEntryItems = lines.filter("[data-type=journal_entry_item]")
      journalEntryItemsDebit = journalEntryItems.find(".debit").sum()
      journalEntryItemsCredit = journalEntryItems.find(".credit").sum()
      journalEntryItemsBalance = Math.round((journalEntryItemsDebit - journalEntryItemsCredit) * Math.pow(10, @precision))
      bankStatementItems = lines.filter("[data-type=bank_statement_item]")
      bankStatementItemsDebit = bankStatementItems.find(".debit").sum()
      bankStatementItemsCredit = bankStatementItems.find(".credit").sum()
      bankStatementItemsBalance = Math.round((bankStatementItemsDebit - bankStatementItemsCredit) * Math.pow(10, @precision))
      journalEntryItemsBalance is -bankStatementItemsBalance

    _clearLinesWithReconciliationLetter: (letter) ->
      return unless letter
      @_unletterItems letter

    _reconciliatedLines: ->
      @_lines().filter (i, e) => @_isLineReconciliated($(e))

    _notReconciliatedLines: ->
      @_lines().filter (i, e) => not @_isLineReconciliated($(e))

    _isLineReconciliated: (line) ->
      !!@_reconciliationLetter(line)

    _isLineLocked: (line) ->
      $(line).find('.locked i').length == 1

    _linesWithReconciliationLetter: (letter) ->
      @_lines().filter (i, e) => @_reconciliationLetter($(e)) is letter

    _reconciliationLetter: (line) ->
      line.find(".details .letter").text()

    # UI UPDATING

    uiUpdate: ->
      @_showOrHideClearButtons()
      @_showOrHideCompleteButtons()
      @_showOrHideNewPaymentButtons()
      @_showOrHideReconciliatedLines()

    _showOrHideClearButtons: ->
      @_reconciliatedLines().each (_index, line) =>
        letter = @_reconciliationLetter($(line))
        bankStatementId = $(line).data('bank-statement-id') || $(".reconciliation-item[data-type='bank_statement_item'][data-letter='#{letter}']").first().data('bank-statement-id')
        $(line).find('.details').html(@_clearButtonTemplate(bankStatementId, letter))

      @_notReconciliatedLines().each ->
        $(this).find('.details').html("<div class='letter'></div>")

    _clearButtonTemplate: (bankStatementId, letter) ->
      removeLabel = I18n.t("front-end.bank_reconciliation.remove")
      "<div class='letter'>#{letter}</div>
       <a href='/backend/bank-reconciliation/letters/#{bankStatementId}?letter=#{letter}' data-remote='true' rel='nofollow' data-method='delete' id='clear'>
         <i></i>
         <span>#{removeLabel}</span>
       </a>"

    _showOrHideCompleteButtons: ->
      @_showAndHideLinkForCollection 'complete',
        $("[data-type=journal_entry_item].selected .details a"),
        $("[data-type=journal_entry_item]:not(.selected) .details a")

    _showAndHideLinkForCollection: (linkType, toShow, toHide) ->
      toShow.each ->
        $(this).attr('id', linkType)
        $(this).find('span').html($(this).data("name-#{linkType}"))
      toHide.each ->
        if $(this).attr('id') == linkType
          $(this).find('span').html('')
          $(this).attr('id', '')

    _setButtonActiveState: ($button, enabled) ->
      if $button.hasClass('btn')
        $button.attr("disabled", !enabled)
        $button.parents('.btn-group').attr("disabled", !enabled)
      else
        $button.parents('.btn-group').find('> button').attr("disabled", !enabled)

    _showOrHideNewPaymentButtons: ->
      selectedBankStatements = @_bankStatementLines().filter(".selected")
      selectedJournalItems = @_journalEntryLines().filter(".selected")
      if selectedBankStatements.length > 0
        @_updateIdsInButtons()
        @_setButtonActiveState $("a.from-selected-bank"), true
      else
        @_setButtonActiveState $("a.from-selected-bank"), false

      if selectedJournalItems.length > 0
        @_updateIdsInButtons()
        @_setButtonActiveState $("a.from-selected-journal"), true
      else
        @_setButtonActiveState $("a.from-selected-journal"), false

      if selectedBankStatements.length == 0 || selectedJournalItems.length == 0
        @_setButtonActiveState $("a.gap-creation"), false
      else
        @_setButtonActiveState $("a.gap-creation"), true

    _showOrHideReconciliatedLines: ->
      if $("#hide-lettered").is(":checked")
        @_reconciliatedLines().hide()
      else
        @_reconciliatedLines().show()

    _updateIdsInButtons: ->
      @_updateItemIdsInButtons()
      @_updateEntryIdsInButtons()

    _updateItemIdsInButtons: ->
      @_updateIdsInButtonsFor('.from-selected-bank, .gap-creation', 'bank_statement_item')

    _updateEntryIdsInButtons: ->
      @_updateIdsInButtonsFor('.from-selected-journal, .gap-creation', 'journal_entry_item')

    _updateIdsInButtonsFor: (selector, type) ->
      selectedLines = @_lines().filter("[data-type=#{type}].selected")
      ids = selectedLines.get().map (line) =>
        @_idForLine(line)
      with_questionmark = new RegExp(".*/\\w+(\\?).*?")
      id_space = new RegExp("(.(?!/)*/\\w+\\?.*?)(&?#{type}_ids\\[\\]=.*)+(&.*)?")
      $(selector).each (i, button) ->
        url = $(button).attr('href')
        if with_questionmark.exec url
          url = url + "&#{type}_ids[]=PLACEHOLDER" unless id_space.exec url
        else
          url = url + "?#{type}_ids[]=PLACEHOLDER" unless id_space.exec url
        url = url.replace(id_space, "$1&#{type}_ids[]=#{ids.join("&#{type}_ids[]=")}$3")
        $(button).attr('href', url)

    # AJAX CALLS

    _letterItems: (lines) ->
      journalLines = lines.filter(":not(.lettered)[data-type=journal_entry_item]")
      journalIds = journalLines.get().map (line) =>
        @_idForLine line
      bankLines = lines.filter(":not(.lettered)[data-type=bank_statement_item]")
      bankIds = bankLines.get().map (line) =>
        @_idForLine line
      url = '/backend/bank-reconciliation/letters'
      $.ajax url,
        type: 'POST'
        dataType: 'JSON'
        data:
          cash_id: $('#cash_id').val()
          journal_entry_items: journalIds
          bank_statement_items: bankIds
        success: (response) =>
          lines.find(".details .letter").text response.letter
          lines.removeClass "selected"
          lines.addClass "lettered"
          $(lines).find(".debit, .credit").trigger "change"
          @uiUpdate()
          return true
        error: (data) ->
          alert 'Error while lettering the lines.'
          console.log data
          return false

    _unletterItems: (letter) ->
      $.ajax
        url: '/backend/bank-reconciliation/letters/'
        type: 'DELETE'
        dataType: 'JSON'
        data:
          cash_id: $('#cash_id').val()
          letter: letter
        success: (response) =>
          lines = @_linesWithReconciliationLetter(response.letter)
          lines.find(".details .letter").text ""
          lines.removeClass "lettered"
          $(lines).find(".debit, .credit").trigger "change"
          @uiUpdate()
          return true
        error: (data) ->
          alert 'Error while unlettering the lines.'
          console.log data
          return false

    _deleteLine: (line) ->
      url = '/backend/bank-statement-items/' + line.data('id')
      $.ajax url,
        type: 'DELETE'
        dataType: 'JSON'
        success: (response) =>
          @_destroyBankStatementItem $(".reconciliation-item[data-id=#{response.id}]")
          return true
        error: (data) ->
          alert 'Error while deleting the line.'
          console.log data
          return false

    # HELPER METHODS

    _lines: ->
      $(".reconciliation-item")

    _bankStatementLines: ->
      $(".reconciliation-item[data-type=bank_statement_item]")

    _journalEntryLines: ->
      $(".reconciliation-item[data-type=journal_entry_item]")

    _filterLinesBy: (lines, filters) ->
      {date, debit, credit} = filters
      lines.filter (i, e) =>
        return if @_dateForLine($(e)) isnt date
        @_debitForLine($(e)) is debit && @_creditForLine($(e)) is credit

    _dateForLine: (line) ->
      line.prevAll(".date-header:first").find('p').text()

    _creditForLine: (line) ->
      creditElement = line.find(".credit")
      @_floatValueForTextOrInput(creditElement)

    _debitForLine: (line) ->
      debitElement = line.find(".debit")
      @_floatValueForTextOrInput(debitElement)

    _floatValueForTextOrInput: (element) ->
      value = if element.is("input") then element.val() else element.text()
      parseFloat(value || 0)

    _idForLine: (line) ->
      parseInt($(line).data('id'))

) ekylibre, jQuery
