((E, $) ->
  'use strict'


  $(document).ready ->
    return unless $('.naming-format-form').length > 0

    E.NamingFormats.changeAllFieldsLabels()
    E.NamingFormats.showExample()


  $(document).on 'click', '.naming-format-form .nested-add', ->
    nestedFields = $('.nested-association .nested-fields')
    newNestedFieldLabel = nestedFields.last().find('.control-label')
    newLabel = "#{ newNestedFieldLabel.text() } #{ nestedFields.length }"

    newNestedFieldLabel.text(newLabel)
    E.NamingFormats.showExample()


  $(document).on 'click', '.naming-format-form .nested-remove', (event) ->
    $(event.target).closest('.nested-association').find('.nested-fields:first .plus-sign').remove()
    E.NamingFormats.changeAllFieldsLabels()
    E.NamingFormats.showExample()


  $(document).on 'change', '.naming-format-form .control-group .controls select', (event) ->
    E.NamingFormats.showExample()


  $(document).on 'click', '.edit_naming_format_land_parcel .form-actions input[type="submit"]', (event) ->
    if $('.naming-format-form input[type="hidden"][name="update_records"]').length < 1
      event.preventDefault()
      $('#namingFormatModal').modal 'show'


  $(document).on 'click', '#namingFormatModal .modal-footer .no-update-plans', ->
    $('.naming-format-form').append('<input type="hidden" name="update_records" value="false"/>')
    $('.simple_form').submit()

    $('#namingFormatModal').modal 'hide'


  $(document).on 'click', '#namingFormatModal .modal-footer .update-plans', ->
    $('.naming-format-form').append('<input type="hidden" name="update_records" value="true"/>')
    $('.simple_form').submit()

    $('#namingFormatModal').modal 'hide'


  E.NamingFormats =
    changeAllFieldsLabels: ->
      $('.nested-association .nested-fields').each (index, nestedField) ->
        fieldLabel = $(nestedField).find('.control-group .controls select').attr('data-label')
        nestedFieldLabel = $(nestedField).find('.control-label')
        newNestedFieldText = "#{ fieldLabel } #{ index + 1 }"
        nestedFieldLabel.text(newNestedFieldText)

    showExample: ->
      fieldsValues = { 'fields_values': [] }

      $('.nested-association .nested-fields').each (index, nestedField) ->
        nestedFieldValue = $(nestedField).find('.control-group .controls select').val()
        fieldsValues['fields_values'].push(nestedFieldValue)

      $.ajax
        url: "/backend/naming_format_land_parcels/build_example",
        data: fieldsValues
        success: (data, status, request) ->
          newExempleElement = $("<h3><em></em>#{ data.example }</h3>")
          $('.naming-format-form .naming-format-example').empty()
          $('.naming-format-form .naming-format-example').append(newExempleElement)


) ekylibre, jQuery
