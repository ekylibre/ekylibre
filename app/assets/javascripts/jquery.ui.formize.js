/*jslint devel: true, browser: true, sloppy: true, vars: true, white: true, maxerr: 50, indent: 2 */

(function ($) {
    // Replaces `$(selector).live("ready", handler)` which don't work
    // It rebinds automatically after each ajax request all not-binded.
    $.behaviours = [];
    $.behave = function (selector, events, handler) {
	events = events.split(/\s+/ig);
	for (var i = 0; i < events.length; i += 1) {
	    event = events[i];
            if (event === "load") {
		$(document).ready(function(event) {
                    $(selector).each(handler);
                    $(selector).prop('alreadyBound', true);
		});
		$.behaviours.push({selector: selector, handler: handler});
            } else {
		$(selector).live(event, handler);
            }
	}
    }
    // Rebinds unbound elements on each ajax request.
    $(document).ajaxComplete(function () {
        for (var behaviour in $.behaviours) {
            behaviour = $.behaviours[behaviour];
            $(behaviour.selector).each(function(index, element){
                if ($(element).prop('alreadyBound') !== true) {
                    behaviour.handler.call($(element));
                    $(element).prop('alreadyBound', true);
                }
            });
        }
    });


    $.ajaxDialogCount = 0;

    $.ajaxDialog = function (url, settings) {
        var frame_id = "dialog-" + $.ajaxDialogCount, width = $(document).width();
        var defaultSettings = {
            header: "X-Return-Code"
        };
        if (settings === null || settings === undefined) { settings = {}; }
        settings = $.extend({}, defaultSettings, settings);
        $.ajax(url, {
            data: {dialog: frame_id},
            success: function(data, textStatus, jqXHR) {
                var frame = $(document.createElement('div'));
                frame.attr({id: frame_id, 'class': 'dialog ajax-dialog', style: 'display:none;'});
                $('body').append(frame);
                frame.html(data);
                frame.prop("dialogSettings", settings);
                frame.dialog({
                    autoOpen: false,
                    show: 'fade',
                    modal: true,
                    width: 'auto',
                    // height: 'auto',
		    height: $(window).height()*0.8
                });
                $.ajaxDialogInitialize(frame);
                frame.dialog("open");
            },
            error: function(jqXHR, textStatus, errorThrown) {
                alert("FAILURE (Error "+textStatus+"): "+errorThrown);
                var frame = $("#" + frame_id);
                frame.dialog("close");
                frame.remove();                
            }
        });
        $.ajaxDialogCount += 1;
    };

    $.ajaxDialogInitialize = function(frame) {
        var frame_id = frame.attr("id");
        var title = frame.prop("dialogSettings")["title"];
        if (title === null || title === undefined) {
            var h1 = $("#" + frame_id + " h1");
            if (h1[0] !== null && h1[0] !== undefined) {
                title = h1.text()
                h1.remove();
            }
        }
        frame.dialog("option", "title", title);
        
        $("#" + frame_id + " form").each(function (index, form) {
            $(form).attr('data-dialog', frame_id);
        });
	
    };

    $.submitAjaxForm = function () {
        var form = $(this);
        var frame_id = form.attr('data-dialog');
        var frame = $('#'+frame_id);
        var settings = frame.prop("dialogSettings");
        
        var field = $(document.createElement('input'));
        field.attr({ type: 'hidden', name: 'dialog', value: frame_id });
        form.append(field);

        $.ajax(form.attr('action'), {
            type: form.attr('method') || 'POST',
            data: form.serialize(),
            success: function(data, textStatus, request) {
                var returnCode = request.getResponseHeader(settings["header"])
                var returns = settings["returns"], unknownReturnCode = true;
                for (var code in returns) {
                    if (returnCode == code && $.isFunction(returns[code])) {
                        returns[code].call(form, frame, data, textStatus, request);
                        unknownReturnCode = false;
                        $.ajaxDialogInitialize(frame);
                        break;
                    }
                }
                if (unknownReturnCode) {
                    if ($.isFunction(settings["defaultReturn"])) {
                        settings["defaultReturn"].call(form, frame);
                    } else {
                        alert("FAILURE (Unknown return code for header " + settings["header"] + "): " + returnCode);
                    }
                }
            },
            error: function(jqXHR, textStatus, errorThrown) {
                alert("FAILURE (Error "+textStatus+"): "+errorThrown);
                var frame = $("#" + frame_id);
                frame.dialog("close");
                frame.remove();                
                // if ($.isFunction(settings["error"])) { settings["error"].call(form, frame, jqXHR, textStatus, errorThrown); }
            }
        });
        return false;
    };

    // Submits dialog forms
    $.behave(".ajax-dialog form[data-dialog]", "submit", $.submitAjaxForm);


})(jQuery);

var Formize = {};

Formize.refreshDependents = function (event) {
    var element = $(this);
    var params = {};
    if (element.val() !== null && element.val() !== undefined) {
	var dependents = element.attr('data-dependents');
	var paramName = element.attr('data-parameter-name') || element.attr('id') || 'value';
        params[paramName] = element.val();
        $(dependents).each(function(index, item) {
            // Replaces element
            var url = $(item).attr('data-refresh');
	    var mode = $(item).attr('data-refresh-mode') || 'replace';
            if (url !== null) {
                $.ajax(url, {
                    data: params,
                    success: function(data, textStatus, response) {
			if (mode == 'update') {
			    $(item).html(response.responseText);
			} else if (mode == 'update-value') {
			    if (element.data("attribute")) {
				$(item).val($.parseJSON(data)[element.data("attribute")]);
			    } else {
				$(item).val(response.responseText);
			    }
			} else {
                            $(item).replaceWith(response.responseText);
			}
                    },
                    error: function(jqXHR, textStatus, errorThrown) {
                        alert("FAILURE (Error "+textStatus+"): "+errorThrown);
                    }
                });
            }
        });
        return true;
    }
    return false;
}

Formize.toggleCheckboxes =  function () {
    var checkable = $(this);
    if (checkable.prop("checked")) {
	$(checkable.attr('data-show')).slideDown();
	$(checkable.attr('data-hide')).slideUp();
    } else {
	$(checkable.attr('data-show')).slideUp();
	$(checkable.attr('data-hide')).slideDown();
    }
};

Formize.toggleRadios = function () {
    $("input[type='radio'][data-show], input[type='radio'][data-hide]").each(Formize.toggleCheckboxes);
};

// Initializes unroll inputs
$.behave('input[data-unroll]', 'load', function() {
    var element = $(this), choices, paramName;
    
    element.unrollCache = element.val();
    element.autocompleteType = "text";
    element.valueField = $('#'+element.attr('data-value-container'))[0];
    if ($.isEmptyObject(element.valueField)) {
        alert('An input '+element.id+' with a "data-unroll" attribute must contain a "data-value-container" attribute');
        element.autocompleteType = "id";
    }
    element.maxResize = parseInt(element.attr('data-max-resize'));
    if (isNaN(element.maxResize) || element.maxResize === 0) { element.maxResize = 64; }
    element.size = (element.unrollCache.length < 32 ? 32 : element.unrollCache.length > element.maxResize ? element.maxResize : element.unrollCache.length);
    
    element.autocomplete({
        source: element.attr('data-unroll'),
        minLength: 1,
        select: function(event, ui) {
            var selected = ui.item;
            element.valueField.value = selected.id;
            element.unrollCache = selected.label;
            element.attr("size", (element.unrollCache.length < 32 ? 32 : element.unrollCache.length > element.maxResize ? element.maxResize : element.unrollCache.length));
            $(element.valueField).trigger("emulated:change");
            return true;
        }
    });
});

// Initializes date fields
$.behave('input[data-datepicker]', "load", function() {
    var element = $(this);
    var locale = element.data("locale");
    var options = $.datepicker.regional[locale];
    if (element.data("date-format") !== null) {
        options['dateFormat'] = element.data("date-format");
    }
    options['altField'] = '#'+element.data("datepicker");
    options['altFormat'] = 'yy-mm-dd';
    options['defaultDate'] = element.val();
    element.datepicker(options);
});


// Initializes date fields
// Can't work properly with actual datetimepicker
// $.behave('input[data-datetimepicker]', "load", function() {
//     var element = $(this);
//     var locale = element.data("locale");
//     var options = $.datepicker.regional[locale];
//     if (element.data("date-format") !== null) {
//         options['dateFormat'] = element.data("date-format");
//     }
//     if (element.data("time-format") !== null) {
//         options['timeFormat'] = element.data("time-format");
//     }
//     options['altField'] = '#'+element.data("datetimepicker");
//     options['altFormat'] = 'yy-mm-dd';
//     options['altFieldTimeOnly'] = false;
//     options['showSecond'] = true;
//     // options['defaultDate'] = element.val();
//     element.datetimepicker(options);
// });


// Initializes resizable text areas
// Minimal size is defined on default size of the area
/*
$.behave('textarea[data-resizable]', "load", function() {
    var element = $(this);
    element.resizable({ 
        handles: "se",
        minHeight: element.height(),
        minWidth: element.width(),
        create: function (event, ui) { $(this).css("padding-bottom", "0px"); },
        stop: function (event, ui) { $(this).css("padding-bottom", "0px"); }
    });
});
*/
// Opens a dialog for a resource creation
$.behave("a[data-add-item]", "click", function() {
    var element = $(this);
    var list_id = '#'+element.attr('data-add-item'), list = $(list_id);
    var url = element.attr('href');
    $.ajaxDialog(url, {
        returns: {
            success: function (frame, data, textStatus, request) {
                var record_id = request.getResponseHeader("X-Saved-Record-Id");
                if (list[0] !== undefined) {
                    $.ajax(list.attr('data-refresh'), {
                        data: {selected: record_id},
                        success: function(data, textStatus, request) {
                            list.replaceWith(request.responseText);
                            $(list_id + ' input').trigger("emulated:change");
                        }
                    });
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

$.behave("input[data-autocomplete]", "load", function () {
    var element = $(this);
    element.autocomplete({
	source: element.data("autocomplete"),
	minLength: parseInt(element.data("min-length") || 1)
    });
});

// Refresh dependents on changes
$.behave("*[data-dependents]", "change", Formize.refreshDependents);
$.behave("*[data-dependents]", "emulated:change", Formize.refreshDependents);
// Compensate for changes made with keyboard
$.behave("select[data-dependents]", "keypress", Formize.refreshDependents);

// Hide/show blocks depending on check boxes
$.behave("input[type='checkbox'][data-show], input[type='checkbox'][data-hide]", "load", Formize.toggleCheckboxes);
$.behave("input[type='checkbox'][data-show], input[type='checkbox'][data-hide]", "change", Formize.toggleCheckboxes)
$.behave("input[type='radio'][data-show], input[type='radio'][data-hide]", "load", Formize.toggleCheckboxes);
$.behave("input[type='radio'][data-show], input[type='radio'][data-hide]", "change", Formize.toggleRadios)
// $.behave("input[data-show], input[data-hide]", "load", Formize.Toggles.ifChecked);
// $.behave("input[data-show], input[data-hide]", "change", Formize.Toggles.ifChecked);
//$.behave("input[type='checkbox'], input[type='radio']", "load", Formize.toggleCheckables);
//$.behave("input[type='checkbox'], input[type='radio']", "change", Formize.toggleCheckables);
