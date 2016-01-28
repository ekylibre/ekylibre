((E, $) ->
  "use strict"

  # Check or uncheck accesses recursively if needed
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

  # Check accesses on click/change events
  $(document).on "click change", "*[data-access]", ->
    $(this).toggleClass("active").checkAccesses()
    return false

    # Through a "role" selector, it can refresh totally on access check
  $(document).on "selector:change", "*[data-selector][data-refresh-access-control-list]", ->
    element = $(this)
    $.ajax element.data("refresh-access-control-list").replace(/ID/g, element.selector("value")),
      dataType: "json"
      success: (data, status, response) ->
        $("*[data-access]").removeClass("active");
        # console.log data.rights
        for resource, actions of data.rights
          for action in actions
            $("*[data-access='#{action}-#{resource}']").addClass("active")
        $("*[data-access]").checkAccesses();
      error: E.ajaxErrorHandler

    return true

) ekylibre, jQuery
