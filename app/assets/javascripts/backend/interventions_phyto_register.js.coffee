((E, $) ->
  # Early-reentry — reveal / hide the PPE + reason block when the checkbox toggles.
  # Weather JSONB cleanup is now handled server-side via
  # Intervention#compact_weather_conditions (before_validation), so no JS needed.
  $(document).on 'change', '#intervention_early_reentry', ->
    $details = $('#early-reentry-details')
    if $(this).is(':checked')
      $details.slideDown(150)
    else
      $details.slideUp(150)
      # Avoid persisting stale text when the user toggles back off.
      $details.find('textarea').val('')
) ekylibre, jQuery
