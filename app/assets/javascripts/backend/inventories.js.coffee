((E, $) ->
  'use strict'

  $(document).ready ->
    $(document).on 'selector:change', '.inventory_product_nature_category .selector-value', (event) =>
      value = event.currentTarget.value
      $('.validate-inventory-category').text($('.validate-inventory-category').data('validateTl'))
      $('.validate-inventory-category').attr('href', "/backend/inventories/new?product_nature_category_id=#{value}")

) ekylibre, jQuery
