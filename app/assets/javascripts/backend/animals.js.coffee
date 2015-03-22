((E, $) ->
  'use strict'
  # Filters supports with given production
  # Hides supports line if needed
  $(document).behave "load selector:set", "#production_id", (event) ->
    production = $(this)
    id = production.selector('value')
    form = production.closest('form')
    url = "/backend/production_supports/unroll?scope[of_currents_campaigns]=true"
    support = form.find("#production_support_id").first()
    if /^\d+$/.test(id)
      url += "&scope[of_productions]=#{id}"
      form.addClass("with-supports")
    else
      form.removeClass("with-supports")
    support.attr("data-selector", url)
    support.data("selector", url)
) ekylibre, jQuery
