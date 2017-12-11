((E, $) ->
  'use strict'

  $(document).ready ->
    Vue.use(VueResource);
    Vue.http.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    element = document.getElementById("intervention_template_form")
    if element != null
      template = JSON.parse(element.dataset.template)
      product_parameters_attributes = JSON.parse(element.dataset.productParametersAttributes)
      product_parameters_attributes.forEach -> (product_parameter) product_parameter._destroy = null
      procedure_names = JSON.parse(element.dataset.procedureNames)
      template.product_parameters_attributes = product_parameters_attributes

      interventionTemplateNew = new Vue {
        el: '#intervention_template_form',
        data:
          template: template,
          procedure_names: procedure_names
        methods:
          addParameter: (procedure) ->
            console.log(procedure)
            template.product_parameters_attributes.push
              id: null,
              quantity: 0,
              product_id: '',
              product_name: '',
              _destroy: null,
              productList: [],
              showList: false,
              procedure: procedure
          removeParameter: (index) ->
            parameter = this.template.product_parameters_attributes[index]
            console.log(parameter)
            if(parameter.id == null)
              this.template.product_parameters_attributes.splice(index, 1)
            else
              this.template.product_parameters_attributes[index]._destroy = 1
          completeDropdown: (index, procedure) ->
            product_parameter = this.attributesForProcedure(procedure)[index]
            $.ajax
              url: '/backend/products/unroll'
              dataType: 'json'
              data:
                keep: true
                scope: product_parameter.procedure.expression,
                q: product_parameter.product_name
              success: (data) =>
                product_parameter.productList = data
                product_parameter.showList = true
              error: ->
                console.log('error')
          updateProduct: (index, procedure, id, name) ->
            product_parameter = this.attributesForProcedure(procedure)[index]
            product_parameter.product_id = id
            product_parameter.product_name = name
            product_parameter.showList = false
          closeChoice: (index) ->
            product_parameter = this.template.product_parameters_attributes[index]
            console.log(product_parameter.showList)
            if product_parameter.showList
              product_parameter.showList = false
          closeAllModal: ->
            this.template.product_parameters_attributes.forEach (p) ->
              p.showList = false
          attributesForProcedure: (procedure) ->
            # List all the attributes for a particular procedure
            this.template.product_parameters_attributes.filter (p) -> p.procedure == procedure
          saveTemplate: ->
            this.$http.post('/backend/intervention_templates', { intervention_template: this.template }).then ((response) =>
              console.log(response)
              debugger
              Turbolinks.visit('/backend/intervention_templates/'  + response.body.id)
            ), (response) =>
              console.log(response)
        }

      document.body.addEventListener "click", (e) ->
        interventionTemplateNew.closeAllModal()

) ekylibre, jQuery
