$(document).ready(function() {
  var form = new Vue ({
    el: '#items-table',
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
      addMerchandise: function (event) {
        console.log(event)
      }
    }
  })
})
