$(document).ready(function() {

  idValue = 1
  $('#items-table').on('cocoon:after-insert', function(e, insertedItem) {

    if(typeof insertedItem != 'undefined') {
      // console.log(insertedItem.first())
      item = insertedItem.first();
      currentId = 'item-' + idValue;
      idValue ++;
      item.attr('id', currentId);

      createVueCalulator('#' + currentId)
      // debugger

    }
  })

  function createVueCalulator(id) {
    var test = new Vue ({
      el: id,
      data: {
        conditionningQuantity: 0,
        conditionning: 0,
      },
      computed: {
        quantity: function () {
          return this.conditionningQuantity * this.conditionning
        }
      },
      methods: {
        validateItem: function() {
          console.log('validate')
        }
      }
    })
  }
})
