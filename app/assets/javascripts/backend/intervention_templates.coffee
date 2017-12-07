((E, $) ->
  'use strict'

  $(document).ready ->
    element = document.getElementById("new_intervention")
    if element != null
      template = JSON.parse(element.dataset.template)

      interventionTemplateNew = new Vue {
        el: '#new_intervention_template',
        data:
          template: template
    }



) ekylibre, jQuery
