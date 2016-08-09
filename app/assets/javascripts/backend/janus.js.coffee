((E, $) ->
  'use strict'

  $(document).on "click", "*[data-janus] a[data-toggle='face']", () ->
    button = $(this)
    $("*[data-toggle='face']").removeClass('active')
    button.addClass('active')
    target = button.attr('data-janus-href')
    $("*[data-face].active").removeClass('active').trigger('face:deactivate')
    $("*[data-face='#{target}']").addClass('active').trigger('face:activate')
    $(window).trigger('resize')
    janus = button.closest("*[data-janus]")
    $.ajax
      url: janus.data("janus")
      data:
        face: target
      type: 'POST'
    return false

  $(document).ready () ->
    $("*[data-face] *[data-list-source]").each ->
      list = $(this)
      face = list.closest("*[data-face]")
      unless face.hasClass("active")
        list_id = list.attr("id")
        $("*[data-list-ref='#{list_id}']").hide()

  $(document).on "face:deactivate", "*[data-face]", ->
    $(this).find("*[data-list-source]").each ->
      list = $(this)
      list_id = list.attr("id")
      $("*[data-list-ref='#{list_id}']").hide()
    return false

  $(document).on "face:activate", "*[data-face]", ->
    $(this).find("*[data-list-source]").each ->
      list = $(this)
      list_id = list.attr("id")
      $("*[data-list-ref='#{list_id}']").show()
    $(this).find("*[data-visualization]").each ->
      unless $(this).hasClass('rebuilt')
        $(this).visualization('rebuild')
        $(this).addClass('rebuilt')
    return false

) ekylibre, jQuery
