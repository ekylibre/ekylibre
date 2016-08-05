(function ($) {

    // Observes fields comparing its value with fixed intervals of time
    // Compensates not quite sure "change" events.
    $(document).behave("load", "*[data-observe]", function () {
	var element = $(this);
	var interval = parseInt(element.data("observe"));
	if (interval === null || interval === undefined) {
	    interval = 1000;
	}
	if (element.get(0).nodeName.toLowerCase() !== "input") {
	    alert("data-observe attribute must be only used with <input>s.");
	    return false;
	}
	element.previousObservedValue = element.val();
	window.setInterval(function () {
	    if (element.val() !== element.previousObservedValue) {
		element.trigger("emulated:change");
		element.previousObservedValue = element.val();
	    }
	}, interval);
	return true;
    });
})(jQuery);