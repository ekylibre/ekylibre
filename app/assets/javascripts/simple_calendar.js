(function ($, undefined) {
    "use strict";

    $(document).on("mouseover", "*[data-simple-calendar] a.previous-month, *[data-simple-calendar] a.next-month", function () {
	var link = $(this), calendar = link.closest('*[data-simple-calendar]');
	link.attr("data-remote", "true")
	    .attr("data-method", "get")
	    .attr("data-update", '#' + calendar.attr("id"));
	
    });


})( jQuery );
