#= require jquery-ui/sortable

(($) ->
  "use strict";

  $(document).ready ->
    $("*[data-cobbles]").sortable
      handle: ".cobble-title"
      tolerance: "pointer"
      placeholder: "cobble cobble-placeholder"
      items: ".cobble"
      containment: "parent"
  true
) jQuery
