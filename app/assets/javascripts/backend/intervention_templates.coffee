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
          completeDropdown: (index) ->
            that = this
            $.ajax
              url: '/backend/intervention_templates/unroll'
              dataType: 'json'
              success: (data) =>
                product_parameter = that.template.product_parameters_attributes[index]
                product_parameter.productList = data.products
                product_parameter.showList = true
              error: ->
                console.log('error')
          updateProduct: (index, id, name) ->
            product_parameter = this.template.product_parameters_attributes[index]
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
            test = this.template.product_parameters_attributes.find (o) => o.procedure == procedure
            console.log(test)
      }

      document.body.addEventListener "click", (e) ->
        interventionTemplateNew.closeAllModal()

) ekylibre, jQuery



  # _openMenu: (search) ->
  #   # console.log "openMenu"
  #   data = {}
  #   if search?
  #     data.q = search
  #   if @element.data("selector-new-item")
  #     data.insert = 1
  #   if @element.data("with")
  #     $(@element.data("with")).each ->
  #       paramName = $(this).data("parameter-name") || $(this).attr("name") || $(this).attr("id")
  #       if paramName?
  #         data[paramName] = $(this).val() || $.trim($(this).html())
  #   menu = @dropDownMenu
  #   url = this.sourceURL()
  #   console.log(url)
  #   $.ajax
  #     url: url
  #     dataType: "html"
  #     data: data
  #     success: (data, status, request) =>
  #       menu.html data
  #       if data.length > 0
  #         menu.show()
  #         @element.trigger('selector:menu-opened')
  #       else
  #         menu.hide()
  #     error: (request, status, error) ->
  #       alert "Selector failure on #{url} (#{status}): #{error}"
