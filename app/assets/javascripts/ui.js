
(function ($) {
    "use strict";

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
                    width: 0,
		    height: 0,
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

    // Redirect to the given location
    $.behave("*[data-redirect]", "ajax:success", function (event, data, status, xhr) {
	var element = $(this);
	window.location.replace(data);
    });

    // Alert on errors
    $.behave("*[data-update], *[data-redirect]", "ajax:error", function (xhr, status, error) {
        alert("FAILURE (Error "+status+"): "+error);
    });


    $.behave("select[data-redirect]", "change keyup", function () {
	var element = $(this), params = {};
	params[element.attr("name") || element.attr("id") || "undefined"] = element.val();
	window.location.replace($.buildURL(element.data("redirect"), params));
    });

    
    $.behave("select[data-show-value]", "load change keypress", function () {
	var element = $(this), prefix = element.data("show-value");
	element.find("option").each(function () {
	    $(prefix + $(this).val()).hide();
	});
	$(prefix + element.val()).show();
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

    // Use element to compute a calculation
    $.behave("*[data-close-dialog]", "click", function () {
	var element = $(this), frame;
	frame = $('#'+element.data("close-dialog"));
	frame.dialog("close");
	return false;
    });



    // Use element to compute a calculation
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

    $.calculateResults();
    window.setInterval($.calculateResults, 300);

    
    $.behave("*[data-balance]", "load", function () {
	var element = $(this), operands = $(this).data("balance").split(/\s\-\s/g).slice(0,2);
	$.behave(operands.join(", "), 'change emulated:change', function () {
	    var plus = $(operands[0]).sum(), minus = $(operands[1]).sum();
	    // alert(operands[0] + " > " + plus);
	    // alert(operands[1] + " > " + minus);
	    if (plus > minus) {
		element.numericalValue(plus - minus);
	    } else {
		element.numericalValue(0);
	    }
	});
    });

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
	return false;
    });

    // Adds parameters
    $.behave("*[data-with]", "ajax:before confirm", function () {
	var element = $(this), params = $.unparam(element.data("params"));
	$(element.data("with")).each(function () {
	    var paramName = $(this).data("parameter-name") || $(this).attr("name") || $(this).attr("id");
	    if (paramName !== null && (typeof(paramName) !== "undefined")) {
		params[paramName] = $(this).val() || $(this).html();
	    }
	});
	element.data("params", $.param(params));
	return true;
    });

    // Adds a HTML
    $.behave("input[data-add-line-unless]", "focusout", function () {
	var element = $(this);
	if (element.numericalValue() !== 0 && !$(element.data("add-line-unless")).hasClass("valid")) {
	    if (element.data("with")) {	
		var params = {};
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

    // Nullify inputs if it filled
    $.behave("input[data-exclusive-nullify]", "keyup", function () {
	var element = $(this);
	if (element.numericalValue() !== 0) {
	    $(element.data("exclusive-nullify")).val('');
	}
    });

    $.behave("*[data-click]", "click", function () {
	$($(this).data("click")).each(function () {
            $(this).trigger("click");
	});
	return false;
    });

    $.behave("input:checkbox[data-add-class-to]", "change", function () {
	var element = $(this), classes = element.data("add-class") || element.attr("class");
	if (element.prop("checked")) {
	    $(element.data("add-class-to")).addClass(classes);
	} else {
	    $(element.data("add-class-to")).removeClass(classes);
	}
    });


    $.behave("*[data-toggle-class]", "click", function () {
	var element = $(this), classes = element.data("toggle-class"), classesArray = classes.split(/\s+/g), gotClasses=true;
	for (var i=0; i < classesArray.length; i += 1) {
	    if (!element.hasClass(classesArray[i])) {
		gotClasses = false;
		break;
	    }
	}
	if (gotClasses) {
	    element.removeClass(classes);
	} else {
	    element.addClass(classes);
	}
    });

    
    // Toggle side menu
    $.behave("a[data-toggle-view-mode]", "click", function () {
	var element = $(this);
	element.attr("href");
	$.ajax(element.data("toggle-view-mode"), {
	    success: function (data, status, xhr) {
		window.location.replace(element.attr("href"));
	    }
	});
	return false;
    });


    // Toggle side menu
    $.behave("a[data-toggle-module]", "click", function () {
	var element = $(this), module = element.closest(".sd-module"), target = module.find(".sd-content"), shown;
	if (element.hasClass("show")) {
	    element.removeClass("show");
	    element.addClass("hide");
	    module.removeClass("collapsed");
	    target.slideDown();
	    shown = 1;
	} else {
	    element.removeClass("hide");
	    element.addClass("show");
	    module.addClass("collapsed");
	    target.slideUp();
	    shown = 0;
	}
	$.ajax(element.attr("href"), {data: {module: element.data("toggle-module"), shown: shown }});
	return false;
    });


    // Live copy
    $.behave("input[data-live-copy-to]", "keyup change emulated:change", function () {
	var element = $(this);
	$(element.data("live-copy-to")).val(element.val());
    });


    // Auto focus
    $.autoFocus = function () {
	this.focus();
	// this.select();
    };
    // $.behave("*[data-autofocus]", "load", $.autoFocus);
    // $.behave("input[type='text']:first", "load", $.autoFocus);
/*    $.behave("*:input:visible:first", "load", $.autoFocus);
    $.behave("*[data-autofocus]:visible", "load", $.autoFocus);*/


    // Toggle visibility
    $(document).on("click", "a[data-toggle-with]", function (event) {
	var element = $(this);
	if (element.is(":visible")) {
	    element.hide();
	    $(element.data('toggle-with')).show();
	} else {
	    $(element.data('toggle-with')).hide()
	    element.show();
	}
	return false;
    });


    // Toggle visibility
    $(document).on("click", "a[data-toggle-visibility]", function (event) {
	var selector = $(this).data('toggle-visibility');
	$(selector).each(function (index) {
	    var target = $(this);
	    if (target.is(":visible")) {
		target.hide();
	    } else {
		target.show();
	    }
	});
	return false;
    });


    $(document).on("click", "a[data-insert-into][data-insert]", function (event) {
	var element = $(this), data, target;
	data = element.data("insert");
	$(element.data("insert-into")).each(function (index) {
	    insertInto(this, '', '', data);
	});
	return false;
    });

    $(document).on("click", "[data-toggle-set]", function (event) {
	var element = $(this), target = $(element.data("toggle-set")), shown;
	if (element.hasClass("collapsed")) {
	    element.removeClass("collapsed");
	    element.addClass("not-collapsed");
	    target.slideDown();
	    shown = 1;
	} else {
	    element.removeClass("not-collapsed");
	    element.addClass("collapsed");
	    target.slideUp();
	    shown = 0;
	}
	return false;
    });

    $(document).on("mouseenter", ".btn", function (event) {
	var button = $(this), text;
	if (button.attr("title") == null || button.attr("title") == undefined) {
	    text = button.find(".text:hidden").first();
	    if (text !== null && text !== undefined) {
		button.attr("title", text.html());
            }
	}
	return true;
    });


})( jQuery );