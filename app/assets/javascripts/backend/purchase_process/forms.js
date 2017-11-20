$(document).ready(function() {
  $('#items-table').on('cocoon:after-insert', function () {
    var form = new Vue({
      el: '#test',
      data: {
        conditionningQuantity: 0,
        conditionning: 0,
        // quantity: 0
      },
      computed: {
        quantity: function () {
          return this.conditionningQuantity * this.conditionning
        }
      }
    })
  })
})
