/* -*- Mode: Java; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2; coding: latin-1 -*- */
/*jslint browser: true */
/* Kame Javascript Inobtrusive Support */

(function() {
  document.on("click", "*[toggle-column]", function(event, element) {
      var columnId = element.readAttribute('toggle-column');
      var column = $(columnId);
      var className = column.readAttribute("cells-class");
      if (className === null) { className = columnId; }
      var search = '.'+className;
      var visibility = '';
      if (column.hasClassName("hidden")) {
        $$(search).each(function(item) { item.removeClassName("hidden"); });
        column.removeClassName("hidden");
        element.removeClassName("im-unchecked");
        element.addClassName("im-checked");
        visibility = 'shown'
      } else {
        $$(search).each(function(item) { item.addClassName("hidden"); });
        column.addClassName("hidden");
        element.removeClassName("im-checked");
        element.addClassName("im-unchecked");
        visibility = 'hidden'
      }
      var url = column.readAttribute("href")
      if (url !== null) {
        new Ajax.Request(url, { method: "post", parameters: {visibility: visibility} });
      }
      event.stop();
    });
  
})();
