((E, $) ->
  'use strict'

  $(document).ready ->
    element = document.getElementById("new_intervention")
    if element != null
      template = JSON.parse(element.dataset.template)
      product_parameters_attributes = JSON.parse(element.dataset.productParametersAttributes)

      product_parameters_attributes.forEach -> (product_parameter) product_parameter._destroy = null

      template.product_parameters_attributes = product_parameters_attributes

      interventionTemplateNew = new Vue {
        el: '#new_intervention_template',
        data:
          template: template
        methods:
          addParameter: ->
            template.product_parameters_attributes.push
              id: null,
              quantity: 0,
              product: '',
              _destroy: null,
          removeParameter: (index) ->
            parameter = this.template.product_parameters_attributes[index]
            console.log(parameter)
            if(parameter.id == null)
              this.template.product_parameters_attributes.splice(index, 1)
            else
              this.template.product_parameters_attributes[index]._destroy = 1
      }



) ekylibre, jQuery
