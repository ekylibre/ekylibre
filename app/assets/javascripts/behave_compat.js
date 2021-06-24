(function ($, Behave) {
  function behaveCompat(element, events, selector, handler) {
    events.split(/\s+/ig).forEach(event => {
      if (event === 'load') {
        Behave.register(element, selector, handler)
      } else {
        console.log("Using Behave for events other than 'load' is deprecated, you should prefer using $.fn.on or ")
        $(element).on(event, selector, handler)
      }
    })
  }

  $.fn.behave = function (events, selector, handler) {
    behaveCompat(this.get(0), events, selector, handler)
  }
  $.behave = function (selector, events, handler) {
    behaveCompat(document, events, selector, handler)
  }

  $(document).ajaxComplete(Behave.refresh)
  $(document).on("cocoon:after-insert page:change", Behave.refresh)
})(jQuery, Behave)
