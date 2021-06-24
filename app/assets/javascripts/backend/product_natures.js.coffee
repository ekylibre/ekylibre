((E, $) ->
  "use strict"

  # Check or uncheck accesses recursively if needed
  $.fn.refreshAbilityValue = () ->
    $(this).each ->
      element = $(this)
      parameters = element.find("*[data-ability-parameter]")
      field = element.find(".ability-value")
      value = element.data("ability")
      if parameters.length > 0
        value += "("
        for index in [0..(parameters.length - 1)]
          value += ", " if index > 0
          value += element.find("*[data-ability-parameter='#{index}']").val()
        value += ")"
      field.val(value)
    return $(this)

  # Refresh ability on change
  $(document).on "click keyup change", "*[data-ability] select[data-ability-parameter]", ->
    $(this).closest("*[data-ability]").refreshAbilityValue()

  $(document).on 'selector:change', '#product_nature_variant_nature_id', ->
    id = $(this).selector("value")
    result = $.getJSON "/backend/product_natures/#{id}/compatible_varieties", (data) =>
      $selector = $("select#product_nature_variant_variety")
      $selector.find('option').remove()
      $selector.append(data.data.map (e) =>  new Option(e.human_name, e.name))


  $(document).on "click", ".abilities-list *[data-add-ability]", ->
    element = $(this)
    root = element.closest(".abilities-list")
    pool = root.find(".abilities")
    select = root.find(element.attr("href"))
    option = select.find("option:selected")
    ability = $("<div>", class: "ability")
    ability.attr("data-ability", option.val())
    ability.append $("<label>").html(option.html())
    ability.append $("<input>").attr("type", "hidden").attr("class", "ability-value").attr("name", element.data("add-ability"))
    if option.data("ability-parameters")?
      parameters = option.data("ability-parameters").split(/\s*,\s*/g)
      for parameter, index in parameters
        ability.append " "
        ability.append $("<select>").attr("data-ability-parameter", index).html(root.find("*[data-ability-parameter-list='#{parameter}']").html())
    ability.append $("<a>").attr("href", "#").attr("data-remove-closest", ".ability").html($("<i>"))
    pool.append(ability)
    ability.refreshAbilityValue()
    return false

  $(document).on "mouseenter", ".nomenclature-item", ->
    unless $(this).attr("title")?
      $(this).attr("title", $(this).find("span").html())

  $(document).on "click change", ".nomenclature-item input", ->
    if $(this).is(":checked")
      $(this).closest("label").addClass("checked")
    else
      $(this).closest("label").removeClass("checked")

  $(document).on "click change", ".control-group.product_nature_frozen_indicators_list .nomenclature-item input", ->
    item = $(this)
    mirror = $(".control-group.product_nature_variable_indicators_list .nomenclature-item input[value='#{item.val()}']")
    if mirror.is(":checked")
      mirror.prop("checked", !item.prop("checked")).trigger("change")

  $(document).on "click change", ".control-group.product_nature_variable_indicators_list .nomenclature-item input", ->
    item = $(this)
    mirror = $(".control-group.product_nature_frozen_indicators_list .nomenclature-item input[value='#{item.val()}']")
    if mirror.is(":checked")
      mirror.prop("checked", !item.prop("checked")).trigger("change")


) ekylibre, jQuery
