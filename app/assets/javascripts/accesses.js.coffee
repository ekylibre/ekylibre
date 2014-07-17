(($) ->
  "use strict"

  $.fn.checkAccesses = () ->
    $(this).each ->
      element = $(this)
      if element.hasClass("active")
        element.find("input").prop("checked", true)
        if element.data("need-accesses")
          $.each element.data("need-accesses").split(' '), (index, value) ->
            $("*[data-access=#{value}]").addClass("active").checkAccesses()
      else
        element.find("input").prop("checked", false)
        if element.data("access")
          $("*[data-need-accesses~=#{element.data('access')}]").removeClass("active").checkAccesses()
    return $(this)

  $(document).on "click change", "*[data-access]", ->
    $(this).toggleClass("active").checkAccesses()
    return false

) jQuery
