
(function ($) {
    // Toggle now with
    $(document).ready(function (event) {
	$('*[data-toggle-now-with]').each(function () {
	    var element = $(this);
	    element.hide();
	    $(element.attr('data-toggle-now-with')).show();
	});
    });


    // Auto-reconnection with time-out
    $.timedSession = {
	timer: null,
	reconnectable: true,
	openReconnection: function () {
	    var body = $('body');
	    var url = body.attr('data-timeout-href');
	    if ($.timedSession.reconnectable && url !== null && url !== undefined) {
		window.clearTimeout($.timedSession.timer); 
		$.timedSession.reconnectable = false;
		// Formize.Dialog.open(url, null, 0);
		$.ajaxDialog(url, {
		    returns: {
			granted: function (frame, data, textStatus, request) {
			    frame.dialog("option", "effect", "fadeOut");
			    frame.dialog("close");
			    $.timedSession.reconnectable = true;
			    $.timedSession.startCountdown();
			},
			denied: function (frame, data, textStatus, request) {
			    frame.html(request.responseText);
			    frame.dialog("widget").effect("shake", {}, 100, function () {
				frame.find('input[type="password"]').focus();
			    });
			}
		    }
		});
		// Adds $.timedSession.reconnectable = true if granted and not denied
	    }
	},	
	startCountdown: function () {
	    var body = $('body');
	    var timeout = body.attr('data-timeout');
	    window.clearTimeout($.timedSession.timer);
	    if (!isNaN(timeout) && $.timedSession.reconnectable) {
		var duration = parseFloat(timeout)*1000;
		$.timedSession.timer = window.setTimeout($.timedSession.openReconnection, duration);
	    }
	}
    };
    $(document).ready($.timedSession.startCountdown);
    $(document).ajaxStop($.timedSession.startCountdown);

    // Set auto resizing
    $.resizeLayout = function () {
	$.layoutResizing.resize($('#body.resizable'), $(window).width(), $(window).height());
	$("input[type='text']:first").select();
	$("input[type='text']:first").focus();
    };
    $.resizeLayoutProperly = function () {
	$.resizeLayout();
	window.setTimeout($.resizeLayout, 300);
    };
    $(document).ready($.resizeLayoutProperly);
    $(window).resize($.resizeLayoutProperly);
    $(window).bind("layout:change", $.resizeLayoutProperly);


    // Splitter
    $.behave("#side-splitter[data-toggle]", "click", function () {
	var splitted, element = $(this), side = $("#side");
	if (toggleElement(side)) {
            splitted = 0;
            element.removeClass("closed");
	} else {
            splitted = 1;
            element.addClass("closed");
	}
	$(window).trigger("layout:change");
	$.ajax(element.attr('data-toggle'), { type: "POST", data: {splitted: splitted}});
	return true;
    });

    // TAbbox
    $.behave(".tabbox > .tabs > .tab[data-tabbox-index]", "click", function () {
	var element = $(this), tabbox = element.closest(".tabbox");
	var index = element.attr('data-tabbox-index');
	if (tabbox !== null) {
	    tabbox.find('.tabs .tab.current, .tabpanels .tabpanel.current').removeClass('current');
	    if (index !== null) {
		tabbox.find('.tabs .tab[data-tabbox-index="' + index + '"], .tabpanels .tabpanel[data-tabbox-index="' + index + '"]').addClass('current');
	    }
	    $.ajax(tabbox.data("tabbox"), {type: "GET", data: {index: index}});
	}
	return true;
    });

    // Update DOM with new system
    $.behave("*[data-update]", "ajax:success", function (event, data, status, xhr) {
	var element = $(this);
	var position = $.trim(element.data("update-at")).toLowerCase();
	if (position === "top") {
	    $(element.data("update")).prepend(data);
	} else if (position === "bottom") {
	    $(element.data("update")).append(data);
	} else if (position === "before") {
	    $(element.data("update")).before(data);
	} else if (position === "after") {
	    $(element.data("update")).after(data);
	} else {
	    $(element.data("update")).html(data);
	}
    });

    $.behave("*[data-update]", "ajax:error", function (xhr, status, error) {
        alert("FAILURE (Error "+status+"): "+error);
    });


    // Old system adaptation to jQuery
    $.behave("a[data-new-item]", "click", function () {
	var element = $(this);
	var list_id = '#'+element.attr('data-new-item'), list = $(list_id);
	$.ajaxDialog(element.attr('href'), {
            returns: {
		success: function (frame, data, textStatus, request) {
                    var record_id = request.getResponseHeader("X-Saved-Record-Id");
                    if (list[0] !== undefined) {
			// Updates manually fields like before
			var combo_box = $('input[data-value-container="' + list.attr("id") + '"]');
			if (combo_box[0] !== undefined) {
			    $.ajax(combo_box.attr('data-combo-box'), {
				data: {id: record_id},
				success: function (data, textStatus, request) {
				    $.setComboBox(combo_box, $.parseJSON(request.responseText)[0]);
				}
			    });
			} else if (list.attr('data-refresh') !== null) { // Select case
			    var parameter = list.attr('data-id-parameter-name') || "selected";
			    var parameters = {};
			    parameters[parameter] = record_id;
			    $.ajax(list.attr('data-refresh'), {
				data: parameters,
				success: function (data, textStatus, request) {
				    list.html(request.responseText);
				    $(list_id).trigger("emulated:change");
				}
			    });
			} else {
			    alert("Unrefreshable list type");
			}
                    }
                    frame.dialog("close");
		},
		invalid: function (frame, data, textStatus, request) {
                    frame.html(request.responseText);
		}
            }
	});
	return false;
    });
   /*
    $.behave("*[data-sum-of]", "load", function () {
	var element  = $(this);
	var selector = element.data("sum-of");
	$.behave(selector, "keyup change emulated:change remove", function () {
	    var total = 0;
	    $(selector).each(function () { 
		total = total + $(this).numericalValue(); 
	    });
	    element.numericalValue(total);
	    element.trigger("emulated:change");
	});
    });


    $.behave("*[data-mul-of]", "load", function () {
	var element  = $(this);
	var selector = element.data("mul-of");
	$.behave(selector, "keyup change emulated:change remove", function () {
	    var total = 1;
	    $(selector).each(function () { 
		total = total * $(this).numericalValue(); 
	    });
	    element.numericalValue(total);
	    element.trigger("emulated:change");
	});
    });
*/
    $.behave("*[data-use]", "load", function () {
	var element = $(this);
	if (element.isCalculationResult()) {
	    element.attr("data-auto-calculate", "true");
	} else {
	    element.removeAttr("data-auto-calculate");
	}
    });

    $.calculateResults = function () {
	$("*[data-use][data-auto-calculate]").each($.calculate);
    };

    // $.calculateResults();
    window.setInterval($.calculateResults, 300);

    $.behave("*[data-less-than-or-equal-to]", "load keyup change emulated:change", function () {
	var element = $(this), maximum = parseFloat(element.data("less-than-or-equal-to"));
	if (element.numericalValue() > maximum) {
	    //element.numericalValue(maximum);
	    element.removeClass("valid");
	    element.addClass("invalid");
	} else {
	    element.removeClass("invalid");
	    element.addClass("valid");
	}
    });

    $.behave("*[data-valid-if-equality-between]", "load", function () {
	var element  = $(this);
	var selector = element.data("valid-if-equality-between");
	$.behave(selector, "load keyup change emulated:change remove", function () {
	    var value = null, equality = true;
	    $(selector).each(function () { 
		if (value === null) { value = $(this).numericalValue(); }
		if (value !== $(this).numericalValue()) { equality = false; }
	    });
	    element.toggleClass("valid", equality);
	    element.toggleClass("invalid", !equality);
	});
    });

    // Removes DOM Element defined by the selector
    $.behave("a[data-remove]", "click", function () {
	$($(this).data("remove")).deepRemove();
	return false
    });

    // Adds a HTML
    $.behave("input[data-add-line-unless]", "focusout", function () {
	var element = $(this);
	if (!$(element.data("add-line-unless")).hasClass("valid")) {
	    if (element.data("with")) {	
		params = {};
		$(element.data("with")).each(function () {
		    var paramName = $(this).data("parameter-name") || $(this).attr("id");
		    if (paramName !== null && paramName !== undefined) {
			params[paramName] = $(this).val() || $(this).html();
		    }
		});
		element.data("params", $.param(params));
	    }
	    $.rails.handleRemote(element);
	}
    });
    

    // Live copy
    $.behave("input[data-live-copy-to]", "keyup", function () {
	var element = $(this);
	$(element.data("live-copy-to")).val(element.val());
    });


    // Auto focus
    $.autoFocus = function () {
	this.focus();
	this.select();
    };
    // $.behave("*[data-autofocus]", "load", $.autoFocus);
    $.behave("input[type='text']:first", "load", $.autoFocus);
    $.behave("*[data-autofocus]", "load", $.autoFocus);

}) (jQuery);