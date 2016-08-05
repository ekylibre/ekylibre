(function ($) {
  'use strict';

  $.Behave = {};
  $.Behave.sequence = 0;
  $.Behave.loads = [];

  // Refresh one behaviour
  $.Behave.refreshOne = function (behaviour) {
    var element;
    behaviour.ref.find(behaviour.selector).each(function (index) {
      var item = $(this);
      if (item.prop('alreadyBound' + behaviour.key) !== true) {
        behaviour.handler.call(item);
        item.prop('alreadyBound' + behaviour.key, true);
      }
    });
  };

  // Refresh all behaviours
  $.Behave.refresh = function () {
    $.each($.Behave.loads, function (index, behaviour) {
      $.Behave.refreshOne(behaviour);
    });
    // console.log("Refresh behaviours");
  };

  // Same API as .on(). Takes in account load events.
  $.fn.behave = function (events, selector, handler) {
    var ref = $(this);
    $.each(events.split(/\s+/ig), function (index, event) {
      var behaviour;
      if (event === "load") {
        behaviour = {ref: ref, selector: selector, handler: handler, key: $.Behave.sequence * 7};
        $.Behave.loads.push(behaviour);
        $.Behave.refreshOne(behaviour);
        $.Behave.sequence += 1;
      } else {
        ref.on(events, selector, handler);
      }
    });
  };
  
  // Retro-compatibility
  $.behave = function (selector, events, handler) {
    $(document).behave(events, selector, handler);
  };

  // Rebinds unbound elements on each ajax request.
  $(document).ajaxComplete($.Behave.refresh);

  // Compatibility with Cocoon and Turbolinks
  $(document).on("cocoon:after-insert page:change", function (event) {
    $.Behave.refresh();
  });

})(jQuery);
