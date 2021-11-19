(function (E) {
  // Sets the time of the selected date if the
  function handleSelectDate() {
    const element = document.querySelector('#sale_invoiced_at')

    if (element) {
      const flatInstance = element._flatpickr

      if (flatInstance) {
        configureFlatpickr(element, flatInstance)
      }
    }
  }

  function configureFlatpickr(element, flatInstance) {
    let lastValue
    flatInstance.set('onOpen', function (selectedDates) {
      lastValue = selectedDates[0]
      if (lastValue != null) {
        lastValue = moment(lastValue)
      }
    })

    flatInstance.set('onValueUpdate', function (selectedDates, _dateStr, instance) {
      const selectedDate = moment(selectedDates[0])
      const now = moment()

      if (selectedDate.isSame(now, 'day')) {
        // If today is selected. We want:
        // if no last_value or last value is an other day, set the time to now
        // else, do nothing
        if (lastValue == null || !selectedDate.isSame(lastValue, 'day')) {
          instance.setDate(now.toDate(), false)
        }
      }

      lastValue = selectedDate
    })
  }
  $(document).on("selector:change", '.sale_items_conditioning_unit > .selector > .selector-value', function(){
    $.ajax('/backend/sales/conditioning_ratio', {
      type: 'get',
      dataType: 'json',
      data: {
        "id": this.value
      },
      success: ((data) => {
        var coeff = 1;
        if (data.coeff && data.coeff != 1) {
          coeff = data.coeff
          $('.unitary-quantity').show();
          var total = $(".total-label")
          if (total.data("colspan") == "basic"){
            total.attr("colspan", parseInt(total.attr("colspan")) + 1)
            total.data("colspan", "updated")
          }
        }
        $(this.closest('.nested-fields')).find('.sale_items_unit_pretax_amount > input').data('coeff', coeff);
      })
    });
  });

  $(document).on('cocoon:after-insert', function(e, insertedItem) {
    if ($('.sale_items_unit_pretax_amount > input').toArray().some((item) => ![undefined, 1].includes($(item).data().coeff))){
      $('.unitary-quantity').show();
    }
  });

  $(document).on('cocoon:after-remove', function(e, insertedItem) {
    if (!$('.sale_items_unit_pretax_amount > input').toArray().some((item) => ![undefined, 1].includes($(item).data().coeff))){
      $('.unitary-quantity').hide();
      var total = $(".total-label")
      if (total.data("colspan") == "updated"){
        total.attr("colspan", parseInt(total.attr("colspan")) - 1)
        total.data("colspan", "basic")
      }
    }
  });

  $(document).behave("load", ".default-unit-amount", function(event) {
    $.ajax('/backend/sales/conditioning_ratio_presence', {
      type: 'get',
      dataType: 'json',
      data: {
        "id": ($('#items-list').data('listRedirect')).match(/\d+/)[0]
      },
      success: ((res) => {
        if (res){
          $('.default-unit-amount').show()
          var colspan = $('.items-list-colspanned');
          colspan.attr("colspan", parseInt(colspan.attr("colspan")) + 1)
        }
      })
    });
  });

  $(document).on("input unit-value:change", ".sale_items_unit_pretax_amount > input", function() {
    var unit_amount = ($(this).val() / $(this).data().coeff).toFixed(2)
    $(this.closest('.nested-fields')).find('.unitary-quantity > .sale_items_base_unit_amount > input').val(unit_amount)
  })

  $(document).on("selector:change", ".sale_items_variant > .selector > .selector-value", function(){
    $.ajax('/backend/sales/default_conditioning_unit', {
      type: 'get',
      dataType: 'json',
      data: {
        "id": this.value
      },
      success: ((data) => {
        var element = $(this.closest('tr')).find('.sale_items_conditioning_unit > .selector > .selector-search')
        var selector_value = $(this.closest('tr')).find('.sale_items_conditioning_unit > .selector > .selector-value')
        var len = 4 * Math.round(Math.round(1.11 * data.unit_name.length) / 4);
        element.attr("size", (len < 20 ? 20 : (len > 80 ? 80 : len)));
        element.val(data.unit_name);
        selector_value.prop("itemLabel", data.unit_name)
        selector_value.val(data.unit_id)
        selector_value.trigger('selector:change')
      })
    });
  });

  E.onDomReady(handleSelectDate)
})(ekylibre)
