/*jslint devel: true, browser: true, sloppy: true, vars: true, white: true, maxerr: 50, indent: 2 */

var Formize = {
    uniqueID: function() {
     	var uid = 'u'+((new Date()).getTime() + "" + Math.floor(Math.random() * 1000000)).substr(0, 18);
	return uid;
    }
};

Formize.Overlay = {
    
    count: 0,
    
    add: function (body) {
        var overlay = $('#overlay')[0];
        if (overlay === null || overlay === undefined) {
            overlay = $(document.createElement('div'));
	    overlay.attr({id: 'overlay', style: 'position:fixed; top:0; left: 0; display: none'});
            $('body').append(overlay);
	    this.resize();
	    overlay.fadeIn('fast');
    	}
        this.count += 1;
    	overlay.css('z-index', this.zIndex());
        return overlay;
    },

    resize: function () {
        var height = $(document).height(), width = $(document).width();
        var overlay = $('#overlay');
	overlay.css({width: width+'px', height: height+'px'});
    },
    
    remove: function() {
        this.count -= 1;
        var overlay = $('#overlay');
    	if (overlay !== null) {
            if (this.count <= 0) {
    		overlay.fadeOut(400, function() { $(this).remove(); });
    	    } else {
    		overlay.css('z-index', this.zIndex());
    	    }
        }
        return this.count;
    },
    
    // Computes a big z-index with interval in order to intercalate dialogs
    zIndex: function() {
    	return (10*this.count + 10000);
    }
};



Formize.Dialog = {

    // Opens a div like a virtual popup
    open: function (url, updated, ratio) {
        var height = $(document).height(), width = $(document).width();
        var dialog_id = 'dialog'+Formize.Overlay.count;
        if (isNaN(ratio)) { ratio = 0.6; }
	
        Formize.Overlay.add();

        $.ajax(url, {
            data: {dialog: dialog_id},
            success: function(data, textStatus, jqXHR) {
		var dialog = $(document.createElement('div'));
                dialog.attr({id: dialog_id, 'data-ratio': ratio, 'data-dialog-update': updated, flex: '1', 'class': 'dialog', style: 'z-index:'+(Formize.Overlay.zIndex()+1)+'; position:fixed; display: none;'});
                $('body').append(dialog);
                dialog.html(data);
		Formize.Dialog.resize(dialog);
		dialog.fadeIn(400, function() { 
		    $(document).trigger("dom:update", dialog.attr('id')); 
		});
            },
            error: function(jqXHR, textStatus, errorThrown) {
                alert("FAILURE (Error "+textStatus+"): "+errorThrown);
                Formize.Overlay.remove();
            }
        });
    },

    resize: function (dialog) {
        var width = $(window).width(), height = $(window).height();
	var ratio = parseFloat(dialog.attr('data-ratio'));
        var w = dialog.width();
        var h = dialog.height();
        if (ratio > 0) {
            w = ratio*width;
	    h = ratio*height;
        }
        dialog.animate({left: ((width-w)/2)+'px', top: ((height-h)/2)+'px', width: w+'px', height: h+'px'});
        return true;
    },

    // Close a virtual popup
    close: function(dialog) {
        dialog = $('#'+dialog);
        dialog.fadeOut(400, function() { $(this).remove(); });
        Formize.Overlay.remove();
        return true;
    },

    submitForm: function(form) {
	var form = $(this);
        var dialog_id = form.attr('data-dialog');
        var dialog = $('#'+dialog_id);
	
        var field = $(document.createElement('input'));
	field.attr({ type: 'hidden', name: 'dialog', value: dialog_id });
        form.append(field);

	$.ajax(form.attr('action'), {
	    type: form.attr('method') || 'POST',
	    data: form.serialize(),
	    success: function(data, textStatus, request) {
		var record_id = request.getResponseHeader("X-Saved-Record-Id");
                if (record_id === null) {
                    // No return => validation error
                    dialog.html(request.responseText);
		    $(document).trigger("dom:update", dialog.attr('id'));
                } else {
                    // Refresh element with its refresh URL
		    var updated_id = '#'+dialog.attr('data-dialog-update'), updated = $(updated_id);
                    if (updated[0] !== undefined) {
			var url = updated.attr('data-refresh');
			$.ajax(url, {
			    data: {selected: record_id},
			    success: function(data2, textStatus2, request2) {
				updated.replaceWith(request2.responseText);
				$(document).trigger("dom:update");
				$(updated_id+' input').trigger("emulated:change");
			    }
			});
                    }
                    // Close dialog
                    Formize.Dialog.close(dialog_id);
                }
	    }
	});
        return false;
    }

};


Formize.refreshDependents = function (event) {
    var element = $(this);
    var dependents = element.attr('data-dependents');
    var params = {};
    if (element.val() !== null && element.val() !== undefined) {
        params[element.attr('id')] = element.val();
        $(dependents).each(function(index, item) {
            // Replaces element
            var url = $(item).attr('data-refresh');
            if (url !== null) {
                $.ajax(url, {
                    data: params,
                    success: function(data, textStatus, response) {
			// alert("Success: "+response.responseText);
                        $(item).replaceWith(response.responseText);
			$(document).trigger("dom:update");
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

Formize.Toggles = {

    ifChecked: function () {
	if (this.checked) {
	    $($(this).attr('data-show')).slideDown();
	    $($(this).attr('data-hide')).slideUp();
	} else {
	    $($(this).attr('data-show')).slideUp();
	    $($(this).attr('data-hide')).slideDown();
	}
    }

}


/**
 * Special method which is a sharthand to bind every element
 * concerned by the selector now and in the future. It correspond
 * to a lack of functionnality of jQuery on 'load' events.
 */
$.rebindeds = [];
function behave(selector, eventType, handler) {
    if (eventType == "load") {
	$(document).ready(function(event) {
	    $(selector).each(handler);
	    $(selector).attr('data-already-bound', 'true');
	});
	$.rebindeds.push({selector: selector, handler:handler});
    } else {
	$(selector).live(eventType, handler);
    }
}

// Rebinds unbound elements on DOM updates.
$(document).bind('dom:update', function(event, element_id) {
    var rebinded;
    for (var i=0; i<$.rebindeds.length; i++) {
	rebinded = $.rebindeds[i];
	$(rebinded.selector).each(function(x, element){
	    if ($(element).attr('data-already-bound') !== 'true') {
		rebinded.handler.call($(element));
		$(element).attr('data-already-bound', 'true');
	    }
	});
    }
});


// Initializes unroll inputs
behave('input[data-unroll]', 'load', function() {
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
behave('input[data-datepicker]', "load", function() {
    var element = $(this);
    var locale = element.attr("data-locale");
    var options = $.datepicker.regional[locale];
    if (element.attr("data-date-format") !== null) {
	options['dateFormat'] = element.attr("data-date-format");
    }
    options['altField'] = '#'+element.attr("data-datepicker");
    options['altFormat'] = 'yy-mm-dd';
    options['defaultDate'] = element.val();
    element.datepicker(options);
});

// Initializes resizable text areas
// Minimal size is defined on default size of the area
behave('textarea[data-resizable]', "load", function() {
    var element = $(this);
    element.resizable({ 
	handles: "se",
	minHeight: element.height(),
	minWidth: element.width(),
	create: function (event, ui) { $(this).css("padding-bottom", "0px"); },
	stop: function (event, ui) { $(this).css("padding-bottom", "0px"); }
    });
});

// Opens a dialog for a ressource creation
behave("a[data-add-item]", "click", function() {
    var element = $(this);
    var list_id = element.attr('data-add-item');
    var url = element.attr('href');
    Formize.Dialog.open(url, list_id);
    return false;
});

// Closes a dialog
behave("a[data-close-dialog]", "click", function() {
    var dialog_id = element.attr('data-close-dialog');
    Formize.Dialog.close(dialog_id);
    return false;
});

// Submits dialog forms
behave("form[data-dialog]", "submit", Formize.Dialog.submitForm);

// Refresh dependents on changes
behave("*[data-dependents]", "change", Formize.refreshDependents);
behave("*[data-dependents]", "emulated:change", Formize.refreshDependents);
// Compensate for changes made with keyboard
behave("select[data-dependents]", "keypress", Formize.refreshDependents);

behave("input[data-show], input[data-hide]", "load", Formize.Toggles.ifChecked);
behave("input[data-show], input[data-hide]", "change", Formize.Toggles.ifChecked);

// Resizes the overlay automatically
$(window).resize(function() {
    Formize.Overlay.resize();
    $('.dialog').each(function(i, dialog) {
	Formize.Dialog.resize($(dialog));
    });
});
