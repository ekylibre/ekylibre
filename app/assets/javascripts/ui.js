
(function ($) {
    // Toggle now with
    $(document).ready(function(event) {
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
    }
    $(document).ready($.timedSession.startCountdown);
    $(document).ajaxStop($.timedSession.startCountdown);

    // Set auto resizing
    $.resizeLayout = function () {
	$.layoutResizing.resize($('#body.resizable'), $(window).width(), $(window).height());
	$("input[type='text']:first").select();
	$("input[type='text']:first").focus();
    }
    $.resizeLayoutProperly = function () {
	$.resizeLayout();
	window.setTimeout($.resizeLayout, 300);
    }
    $(document).ready($.resizeLayoutProperly);
    $(window).resize($.resizeLayoutProperly);
    $(window).bind("layout:change", $.resizeLayoutProperly);


    // Splitter
    $.behave("#side-splitter[data-toggle]", "click", function() {
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
    $.behave(".tabbox > .tabs > .tab[data-tabbox-index]", "click", function() {
	var element = $(this), tabbox = element.closest(".tabbox");
	var index = element.attr('data-tabbox-index');
	if (tabbox !== null) {
	    tabbox.find('.tabs .tab.current, .tabpanels .tabpanel.current').removeClass('current');
	    if (index !== null) {
		tabbox.find('.tabs .tab[data-tabbox-index="' + index + '"], .tabpanels .tabpanel[data-tabbox-index="' + index + '"]').addClass('current');
	    }
	    $.ajax(tabbox.attr("data-tabbox"), {type: "GET", data: {index: index}});
	}
	return true;
    });


    $.behave("a[data-new-item]", "click", function() {
	var element = $(this);
	var list_id = '#'+element.attr('data-new-item'), list = $(list_id);
	$.ajaxDialog(element.attr('href'), {
            returns: {
		success: function (frame, data, textStatus, request) {
                    var record_id = request.getResponseHeader("X-Saved-Record-Id");
                    if (list[0] !== undefined) {
			// Updates manually fields like before
			var combo_box = $('input[data-value-container="' + list.attr("id") + '"]')
			if (combo_box[0] !== undefined) {
			    $.ajax(combo_box.attr('data-combo-box'), {
				data: {id: record_id},
				success: function (data, textStatus, request) {
				    $.setComboBox(combo_box, $.parseJSON(request.responseText)[0]);
				}
			    });
			} else if (list.attr('data-refresh') !== null) {
			    var parameter = list.attr('data-id-parameter-name') || "selected";
			    var parameters = {};
			    parameters[parameter] = record_id;
			    $.ajax(list.attr('data-refresh'), {
				data: parameters,
				success: function (data, textStatus, request) {
				    list.html(request.responseText);
				    $(list_id + ' input').trigger("emulated:change");
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
            },
	});
	return false;
    });


    // Auto focus
    $.autoFocus = function () {
	this.focus();
	this.select();
    }
    // $.behave("*[data-autofocus]", "load", $.autoFocus);
    $.behave("input[type='text']:first", "load", $.autoFocus);

}) (jQuery);