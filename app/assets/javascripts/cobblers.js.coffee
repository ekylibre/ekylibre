#= require jquery-ui/widgets/sortable

((E, $) ->
  "use strict";

  E.cobblers =
    save: (widget) ->
      list = []
      widget.find("> .cobbles-body > .cobble").each () ->
        list.push $(this).attr("id")
      console.log list
      $.ajax
        url: widget.data("cobbles")
        type: 'patch'
        data:
          order: list

  $(document).ready ->
    $("*[data-cobbles]").sortable
      handle: ".cobble-title"
      tolerance: "pointer"
      placeholder: "cobble cobble-placeholder"
      items: ".cobble"
      containment: "parent"
      update: ->
        $(window).trigger('resize')
        E.cobblers.save($(this))
  true
) ekylibre, jQuery
