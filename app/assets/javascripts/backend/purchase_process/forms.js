(function(E, $) {
  'use strict'
  $(document).ready(function() {

    var idValue = 1
    $('#items-table').on('iceberg:inserted', function(e, insertedItem) {
      if(typeof insertedItem != 'undefined') {
        var item = insertedItem.first();
        var currentId = 'item-' + idValue;
        idValue ++;
        item.attr('id', currentId);

        // console.log(insertedItem)
        createVueCalulator('#' + currentId, insertedItem)
        // debugger
        // E.toggleValidateButton(container.first())

      }
    })

    function createVueCalulator(id, container) {
      var test = new Vue ({
        el: id,
        data: {
          conditionningQuantity: 0,
          conditionning: 0,
          quantity: 0,
        },
        watch: {
          conditionningQuantity: function (val) {
            this.quantity = val * this.conditionning
          },
          conditionning: function (val) {
            this.quantity = this.conditionningQuantity * val
          }
        },
        methods: {
          validateItem: function() {
            console.log('validate')
          }
        }
      })
      console.log('end')
    }
  })
}) (ekylibre, jQuery);
