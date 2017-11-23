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
      new Vue ({
        el: id,
        data: {
          conditionningQuantity: 0,
          conditionning: 0,
          quantity: 0,
          unitPretaxAmount: 0,
          reductionPercentage: 0,
          pretaxAmount: 0,
        },
        watch: {
          conditionningQuantity: function (val) {
            this.quantity = val * this.conditionning
            this.setPretaxAmount()
          },
          conditionning: function (val) {
            this.quantity = this.conditionningQuantity * val
            this.setPretaxAmount()
          },
          reductionPercentage: function(val) {
            this.setPretaxAmount()
          }
        },
        methods: {
          validateItem: function() {
            console.log('validate')
          },
          setPretaxAmount: function() {
            var noReductionAmount = this.quantity * this.unitPretaxAmount
            if(this.reductionPercentage != 0 ) {
              this.pretaxAmount = noReductionAmount - (noReductionAmount * this.reductionPercentage / 100)
            } else {
              this.pretaxAmount = noReductionAmount
            }
          }
        }
      })
      console.log('end')
    }
  })
}) (ekylibre, jQuery);
