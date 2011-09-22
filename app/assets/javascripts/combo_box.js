/*
 * jQuery Combo Box
 */

(function ($) {



    $.setComboBox = function (element, selected) {
        element.prop("valueField").val(selected.id);
        element.comboBoxCache = selected.label;
	element.val(element.comboBoxCache);
        element.attr("size", (element.comboBoxCache.length < 32 ? 32 : element.comboBoxCache.length > element.maxSize ? element.maxSize : element.comboBoxCache.length));
        element.prop("valueField").trigger("emulated:change");
	return true;
    };

    $.getComboBox = function (element) {
	return {id: element.prop("valueField").val(), label: element.val()};
    };

    // Initializes combo-box controls
    $.initializeComboBox = function () {
        var element = $(this);
        if (element.prop("alreadyBound") !== true) {
            element.comboBoxCache = element.val();
            element.prop("valueField", $('#' + element.attr('data-value-container')));
            if ($.isEmptyObject(element.prop("valueField")[0])) {
                alert('An input ' + element.id + ' with a "data-combo-box" attribute must contain a "data-value-container" attribute (#' + element.attr('data-value-container') + ')');
            }
            element.maxSize = parseInt(element.attr('data-max-size'), 10);
            if (isNaN(element.maxSize) || element.maxSize === 0) { element.maxSize = 64; }
            element.size = (element.comboBoxCache.length < 32 ? 32 : element.comboBoxCache.length > element.maxSize ? element.maxSize : element.comboBoxCache.length);
            
            element.autocomplete({
                source: element.attr('data-combo-box'),
                minLength: 1,
                select: function (event, ui) {
		    return $.setComboBox(element, ui.item);
                }
            });
            element.prop("alreadyBound", true);
        }
        return true;
    };
    $.initializeComboBoxes = function () {
	$('input[data-combo-box]').each($.initializeComboBox);
    }
    // Bind elements with the method 
    // $('input[data-combo-box]').ready($.initializeComboBoxes);
    $(document).ready($.initializeComboBoxes);
    $(document).ajaxComplete($.initializeComboBoxes);

    $("a[data-permute-combo-box]").live("click", function () {
	var elements = $($(this).attr("data-permute-combo-box"));
	for (var i = 0; i < elements.length; i += 1) {
	    if ($(elements[i]).attr("data-combo-box") === undefined || $(elements[i]).attr("data-combo-box") === null) {
		elements[i] = $("input[data-value-container='" + $(elements[i]).attr("id") + "']");
	    }
	}
	if (elements.length > 1) {	    
	    var vt = $.getComboBox($(elements[0]));
	    for (var i = 1; i < elements.length; i += 1) {
		$.setComboBox($(elements[i-1]), $.getComboBox($(elements[i])));
	    }
	    $.setComboBox($(elements[elements.length - 1]), vt);
	}
	return false;
    });
    
})(jQuery);