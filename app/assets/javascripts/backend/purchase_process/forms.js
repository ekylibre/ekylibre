$(document).ready(function() {
  $('#items-table').on('cocoon:after-insert', function (event, item) {
    console.log(event);
    var form = new Vue({
      el: item,
      data: {
        conditionningQuantity: 0,
        conditionning: 0,
      },
      computed: {
        quantity: function () {
          return this.conditionningQuantity * this.conditionning
        }
      }
    })
  })
})
