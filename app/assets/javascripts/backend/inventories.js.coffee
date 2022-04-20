((E, $) ->
  'use strict'

  $(document).ready ->
    $(document).on 'selector:change input', '#inventory_achieved_at, .inventory_financial_year .selector-value, .inventory_product_nature_category .selector-value', (event) =>
      achieved_at = $('#inventory_achieved_at').val()
      financial_year_id = $('.inventory_financial_year .selector-value')[0].value
      nature_category_id = $('.inventory_product_nature_category .selector-value')[0].value
      url = if nature_category_id then "/backend/inventories/new?product_nature_category_id=#{nature_category_id}" else "/backend/inventories/new?product_nature_category=all"
      url += if financial_year_id then "&financial_year_id=#{financial_year_id}" else ''
      url += if achieved_at then "&achieved_at=#{achieved_at}" else ''
      $('.validate-inventory-category').attr('href', url)

) ekylibre, jQuery
