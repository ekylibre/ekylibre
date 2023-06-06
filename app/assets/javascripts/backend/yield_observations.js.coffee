$(document).on 'change', '.edit_yield_observation .plant-fields select', (event) ->
  id = event.target.value
  prefix = event.target.id.split('product_id')[0]
  map_selector = prefix + 'working_zone'
  $.ajax
    url: "/backend/plants/#{id}.json"
    success: (data) ->
      value = $.parseJSON(data.shape)
      if (value.geometries? and value.geometries.length > 0) || (value.coordinates? and value.coordinates.length > 0)
        element = $("##{map_selector}")
        element.mapeditor "edit", value
        try
          element.mapeditor "view", "edit"

$(document).on 'selector:change', '#yield_observation_activity_id', (event) ->
  activity_id = $(event.target).parent().find('.selector-value')[0].value
  $.ajax
    url: "/backend/activities/#{activity_id}.json"
    success: (data) ->
      unroll_selector = $('#yield_observation_vegetative_state_id')
      scope_url = decodeURIComponent(unroll_selector.data('selector'))
      string_to_replace = scope_url.split('scope[of_variety]=')[1]
      final_url = scope_url.replace(string_to_replace, data.variety)
      unroll_selector.attr('data-selector', final_url)

$(document).on 'cocoon:after-insert', '.issues', (event, insertedItem) ->
  selected_category = $('select#issue_nature_category').find('option:selected').attr('value')
  insertedItem.find('.issue-category').html(selected_category)
  insertedItem.find('select').find('option').each ->
    $(this).remove() unless $(this).data('category') == selected_category
