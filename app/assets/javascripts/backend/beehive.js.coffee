#= require jquery.blank
#= require jquery-ui/sortable

(($) ->
  "use strict";

  $.beehive =
    save: (beehive) ->
      children = beehive
        .find("*[data-beehive-box]")
        .map(->
          type: "hbox"
          children: $(this).find("*[data-beehive-cell]").map( ->
            type: "cell"
            name: $(this).data("beehive-cell")
          ).get()
        ).get()
      console.log children
      $.ajax
        url: beehive.data("beehive-save-url")
        type: 'patch'
        data:
          type: "root"
          children: children

    reset: (beehive) ->
      $.ajax
        url: beehive.data("beehive-reset-url")
        type: 'post'
        success: (data, status, request) ->
          document.location.reload(true)

    setSortable: (beehive) ->
      $.beehive.addCellProposers(beehive)
      beehive.find("*[data-beehive-box]")
        .sortable
          connectWith: "div[data-beehive-box]"
          handle: ".cell-title"
          tolerance: "pointer"
          placeholder: "cell cell-placeholder"
          items: "> *[data-beehive-cell]"
          dropOnEmpty: true
          update: ->
            $(window).trigger('resize')
            $.beehive.save(beehive)
        .disableSelection()

    addBox: (beehive) ->
      button = beehive.find("*[data-beehive-task='new-box']")
      box = $("<div>")
        .addClass("box box-horizontal")
        .attr("data-beehive-box", "horizontal")
        .insertBefore(button)
      $.beehive.setSortable beehive

    addCell: (beehive) ->
      select = beehive.find("select[name='cell']")
      name = select.val()
      console.log "Adding #{name} cell..."
      $.beehive.addCellProposers(beehive)
      box = beehive.find("*[data-beehive-box]").first()
      locals = beehive.find(".local-cells .cell[data-beehive-cell='#{name}']")
      if locals.length > 0
        locals.first().clone().appendTo(box)
      else
        $.ajax
          url: "/backend/cells/#{name}_cell"
          data:
            beehive: beehive.data("beehive")
            cell: name
            layout: true
          dataType: "html"
          success: (data, status, request) ->
            console.log "Success..."
            cell = $(data)
            cell.appendTo(box)
            cell.trigger('cell:load')
            $(window).trigger('resize')
            $.beehive.save(beehive)
          error: (request, status, error) ->
            console.log("Error while retrieving full cell #{name}: #{error}")
            element.html(request.responseXML)
            element.trigger('cell:error')

    addCellProposers: (beehive) ->
      if beehive.find("*[data-beehive-box]").length <= 0
        $.beehive.addBox(beehive)

  $(document).on "click", "a[href][data-beehive-task='configure']", ->
    element = $(this)
    beehive = $(element.attr("href"))
    if beehive.hasClass "configuring"
      beehive.removeClass "configuring"
      beehive.find("*[data-beehive-box]").sortable("destroy")
      element.removeClass("active")
      $(window).trigger('resize')
    else
      beehive.addClass "configuring"
      element.addClass("active")
      $.beehive.setSortable beehive
    return false

  $(document).on "click", "a[href][data-beehive-task='fullscreen']", ->
    element = $(this)
    beehive = $(element.attr("href"))[0]
    if beehive.requestFullscreen
      beehive.requestFullscreen()
    else if beehive.requestFullScreen
      beehive.requestFullScreen()
    else if beehive.msRequestFullscreen?
      beehive.msRequestFullscreen()
    else if beehive.mozRequestFullScreen?
      beehive.mozRequestFullScreen()
    else if beehive.webkitRequestFullscreen?
      beehive.webkitRequestFullscreen()
    else
      console.warn "Cannot request fullscreen"
    return false

  $(document).on "click", "a[href][data-beehive-task='new-box']", ->
    console.log "New box..."
    element = $(this)
    $.beehive.addBox $(element.attr("href"))
    return false

  $(document).on "click", "a[href][data-beehive-task='new-cell']", ->
    console.log "New cell..."
    element = $(this)
    $.beehive.addCell $(element.attr("href"))
    return false

  $(document).on "click", "a[href][data-beehive-task='reset']", ->
    console.log "Reset config..."
    element = $(this)
    $.beehive.reset $(element.attr("href"))
    return false

  $(document).on "click", "*[data-beehive-cell] a[href][data-beehive-remove='cell']", ->
    element = $(this)
    beehive = $(element.attr("href"))
    cell = element.closest("*[data-beehive-cell]")
    cell.remove()
    $(window).trigger('resize')
    $.beehive.save(beehive)
    return false

  $.fn.raiseContentErrorToCellTitle = ->
    cells = $(this);
    cells.each ->
      cell = $(this);
      if cell.find('.cell-content .error').length > 0
        cell.closest('.beehive')
          .find('.cell-title[href="#' + cell.attr('id') + '"]')
          .closest('li')
          .addClass('error')

  $(document).on 'page:load', '.beehive .cell', $.fn.raiseContentErrorToCellTitle

  $(document).ready ->
    $(".beehive .cell").raiseContentErrorToCellTitle()
    $("*[data-cell]").each (index) ->
      element = $(this)
      cell = element.closest("*[data-beehive-cell]")
      cell.addClass("loading")
      element.html("<i class='cell-indicator'></i>")
      $.ajax(element.data("cell"), {
        dataType: "html",
        success: (data, status, request) ->
          cell.removeClass("loading")
          if $.isBlank(data)
            cell.addClass("blank")
            element.trigger('cell:empty')
          else
            element.html(data)
            element.trigger('cell:load')
        error: (request, status, error) ->
          # alert("#{status} on cell (#{element.data('cell')}): #{error}")
          console.log("Error while retrieving #{element.data('cell')} cell content: #{error}")
          cell.removeClass("loading")
          cell.addClass("errored")
          element.html(request.responseXML)
          element.trigger('cell:error')
      })

  true
) jQuery
