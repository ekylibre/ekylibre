(function (E) {

  function unitSelectorChange() {
    const defaultUnit = document.querySelector('#product_nature_variant_default_unit_id')

    defaultUnit.addEventListener("unroll:selector:change", function(e) {
      const unitName = document.querySelector('#product_nature_variant_unit_name')
      const defaultQuantity = document.querySelector('#product_nature_variant_default_quantity')
      if (!e.detail.wasInitializing){
        if(unitName.value===''&& parseFloat(defaultQuantity.value)===1){
          unitName.value = this.value
        }
      }
    })
  }

  E.onDomReady(unitSelectorChange)
})(ekylibre)
