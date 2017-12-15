((E, $) ->
  'use strict'

  $(document).ready ->
    Vue.use(VueResource);
    Vue.http.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    element = document.getElementById("intervention_template_form")
    if element != null
      template = JSON.parse(element.dataset.template)
      product_parameters_attributes = JSON.parse(element.dataset.productParametersAttributes)
      number = 0
      product_parameters_attributes.forEach (product_parameter) ->
        product_parameter._destroy = null
        product_parameter.id_number = number
        number++
      procedure_names = JSON.parse(element.dataset.procedureNames)
      template.product_parameters_attributes = product_parameters_attributes
      association_activities_attributes = JSON.parse(element.dataset.associationActivitiesAttributes)
      association_activities_attributes.forEach (association) -> association._destroy = null
      template.association_activities_attributes = association_activities_attributes

      interventionTemplateNew = new Vue {
        el: '#intervention_template_form',
        data:
          template: template,
          procedure_names: procedure_names
          activitiesList: []
          productList: []
          errors: {},
        created: ->
          if this.template.association_activities_attributes.length == 0
            this.addAssociation()
        methods:
          addParameter: (procedure) ->
            template.product_parameters_attributes.push
              id: null,
              quantity: 0,
              unit: 'unit'
              product_name: '',
              _destroy: null,
              productList: [],
              showList: false,
              procedure: procedure
              product_nature_id: ''
              product_nature_variant_id: ''
              # number to authenticate precise element in the array
              id_number: template.product_parameters_attributes.length
          addAssociation: ->
            template.association_activities_attributes.push
              id: null
              activity_label: ''
              activity_id: ''
              _destroy: null
              showList: false
          removeAssociation: (index) ->
            association = this.template.association_activities_attributes[index]
            if(association.id == null)
              this.template.association_activities_attributes.splice(index, 1)
            else
              this.template.association_activities_attributes[index]._destroy = "1"
          updateAssociation: (index, activity) ->
            association = this.template.association_activities_attributes[index]
            association.activity_label = activity.label
            association.activity_id = activity.id
            association.showList = false
          listOfActivities: (index) ->
            association = this.template.association_activities_attributes[index]
            this.$http.get('/backend/activities/unroll', { params: { q: association.activity_label }}).then ((response) =>
                association = association
                this.activitiesList = response.body
                association.showList = true
              ), (response) =>
                console.log(response)
          removeParameter: (id_number) ->
            parameter = this.template.product_parameters_attributes[id_number]
            if(parameter.id == null)
              this.template.product_parameters_attributes.splice(id_number, 1)
              this.updateParameterIdNumber()
            else
              this.template.product_parameters_attributes[id_number]._destroy = "1"
          updateParameterIdNumber: ->
            number = 0
            this.template.product_parameters_attributes.forEach (p) ->
              p.id_number = number
              number++
          completeDropdown: (index, procedure) ->
            product_parameter = this.attributesForProcedure(procedure)[index]
            if procedure.is_tool
              url = '/backend/product_natures/unroll'
            else
              url = '/backend/product_nature_variants/unroll'
            $.ajax
              url: url
              dataType: 'json'
              data:
                keep: true
                scope: product_parameter.procedure.expression,
                q: product_parameter.product_name
              success: (data) =>
                this.productList = data
                product_parameter.showList = true
              error: ->
                console.log('error')
          updateProduct: (index, procedure, id, name) ->
            product_parameter = this.attributesForProcedure(procedure)[index]
            product_parameter.product_name = name
            product_parameter.showList = false
            if procedure.is_tool
              product_parameter.product_nature_id = id
            else
              product_parameter.product_nature_variant_id = id
          closeChoice: (index) ->
            product_parameter = this.template.product_parameters_attributes[index]
            console.log(product_parameter.showList)
            if product_parameter.showList
              product_parameter.showList = false
          closeAllModal: ->
            this.template.product_parameters_attributes.forEach (p) ->
              p.showList = false
            this.template.association_activities_attributes.forEach (p) ->
              p.showList = false
          attributesForProcedure: (procedure) ->
            # List all the attributes for a particular procedure
            this.template.product_parameters_attributes.filter (p) -> p.procedure.type == procedure.type
          saveTemplate: ->
            if this.template.id == null
              this.$http.post('/backend/intervention_templates', { intervention_template: this.template }).then ((response) =>
                Turbolinks.visit('/backend/intervention_templates/'  + response.body.id)
              ), (response) =>
                # TODO manage errors
                console.log(response)
                this.errors = response.data.errors
            else
              this.$http.put("/backend/intervention_templates/#{this.template.id}", { intervention_template: this.template }).then ((response) =>
                Turbolinks.visit("/backend/intervention_templates/#{response.body.id}/")
              ), (response) =>
                # TODO manage errors
                console.log(response)
                this.errors = response.data.errors
          updateUnit: (procedure, index, event) ->
            product_parameter = this.attributesForProcedure(procedure)[index]
            product_parameter.unit = event.target.value
        }

      document.body.addEventListener "click", (e) ->
        interventionTemplateNew.closeAllModal()

) ekylibre, jQuery
