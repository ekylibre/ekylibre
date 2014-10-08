/* -*- mode: javascript; indent-tabs-mode: nil; -*- */

function toggleElement(element, show, reverseElement) {
    element = $(element);
    if (show === null || show === undefined) {
        show = (element.css("display") === "none");
    }
    if (show) {
        element.show();
        if (reverseElement !== undefined) {
            $(reverseElement).hide();
        }
    } else {
        element.hide();
        if (reverseElement !== undefined) {
            $(reverseElement).show();
        }
    }
    return show;
}

function toggleCheckBox(element, checked) {
    element = $(element);
    if (element[0] === null || element[0] === undefined) {
        if (checked === null || checked === undefined) {
            checked = element.prop("checked");
        }
        element.prop("checked", !checked);
        element.trigger("click");
    }
    return element.checked;
}

function insertInto(input, repdeb, repfin, middle) {
    if(repfin == 'undefined') {repfin=' ';}
    if(middle == 'undefined') {middle=' ';}
    input.focus();
    var insText;
    var pos;
    /* pour l'Explorer Internet */
    if(typeof document.selection != 'undefined') {
        /* Insertion du code de formatage */
        var range = document.selection.createRange();
        insText = range.text;
        if (insText.length <= 0) { insText = middle; }
        range.text = repdeb + insText + repfin;
        /* Ajustement de la position du curseur */
        range = document.selection.createRange();
        if (insText.length === 0) {
            range.move('character', -repfin.length);
        } else {
            range.moveStart('character', repdeb.length + insText.length + repfin.length);
        }
        range.select();
    }
    /* pour navigateurs plus récents basés sur Gecko*/
    else if(typeof input.selectionStart != 'undefined')  {
        /* Insertion du code de formatage */
        var start = input.selectionStart;
        var end = input.selectionEnd;
        insText = input.value.substring(start, end);
        if (insText.length <= 0) { insText = middle; }
        input.value = input.value.substr(0, start) + repdeb + insText + repfin + input.value.substr(end);
        /* Ajustement de la position du curseur */
        if (insText.length === 0) {
            pos = start + repdeb.length;
        } else {
            pos = start + repdeb.length + insText.length + repfin.length;
        }
        input.selectionStart = pos;
        input.selectionEnd = pos;
    }
    /* pour les autres navigateurs */
    else {
        /* requête de la position d'insertion */
        var re = new RegExp('^[0-9]{0,3}$');
        while(!re.test(pos)) {
            pos = prompt("Insertion à la position (0.." + input.value.length + ") :", "0");
        }
        if(pos > input.value.length) {
            pos = input.value.length;
        }
        /* Insertion du code de formatage */
        insText = prompt("Veuillez entrer le texte à formater :");
        if (insText.length <= 0) { insText = middle; }
        input.value = input.value.substr(0, pos) + repdeb + insText + repfin + input.value.substr(pos);
    }
}



function formatNumber(value, decimal, separator, thousand) {
    var deci=Math.round(Math.pow(10, decimal)*(Math.abs(value)-Math.floor(Math.abs(value))));
    var val=Math.floor(Math.abs(value));
    if ((decimal===0)||(deci==Math.pow(10,decimal))) {val=Math.floor(Math.abs(value)); deci=0;}
    var valFormat=val+"";
    var nb=valFormat.length;
    for (var i=1;i<4;i++) {
        if (val>=Math.pow(10,(3*i))) {
            valFormat=valFormat.substring(0,nb-(3*i))+thousand+valFormat.substring(nb-(3*i));
        }
    }
    if (decimal>0) {
        var decim="";
        for (var j=0;j<(decimal-deci.toString().length);j++) {decim+="0";}
        deci=decim+deci.toString();
        valFormat=valFormat+separator+deci;
    }
    if (parseFloat(value)<0) {valFormat="-"+valFormat;}
    return valFormat;
}


function formatNumber2(value, precision, separator, thousand) {
    if (isNaN(value)) return "NaN";
    var splitted, integers, decimals, coeff = 1, formatted;
    if (value < 0) coeff = -1;
    splitted = Math.abs(value).toString().split(/\./g);
    // alert(splitted.length);
    integers = splitted[0].replace(/^0+[1-9]+/g, '');
    decimals = (splitted[1] || '').replace(/0+$/g, '');
    while (decimals.length < precision) {
        decimals = decimals + "0";
    }
    formatted = integers;
    if (!(/^\s*$/).test(decimals)) {
        formatted = formatted + separator + decimals;
    }
    return formatted;
}

// Display a number with money presentation
function toCurrency(value) {
    return formatNumber2(value, 2, ".", "");
}



(function ($) {


    /*
     * Resizing
     */
    var lr;
    $.layoutResizing = lr = {

        getNumericalStyle: function(element, style) {
            element = $(element);
            var value = element.css(style);
            if (value === null) {
                value = "0";
            }
            return Math.floor(parseFloat(value.replace(new RegExp("[^\\.0-9]", "ig"), "")));
        },

        getBorderDimensions: function(element) {
            element = $(element);
            var t = lr.getNumericalStyle(element, 'padding-top')+lr.getNumericalStyle(element, 'margin-top')+lr.getNumericalStyle(element, 'border-top-width');
            var r = lr.getNumericalStyle(element, 'padding-right')+lr.getNumericalStyle(element, 'margin-right')+lr.getNumericalStyle(element, 'border-right-width');
            var b = lr.getNumericalStyle(element, 'padding-bottom')+lr.getNumericalStyle(element, 'margin-bottom')+lr.getNumericalStyle(element, 'border-bottom-width');
            var l = lr.getNumericalStyle(element, 'padding-left')+lr.getNumericalStyle(element, 'margin-left')+lr.getNumericalStyle(element, 'border-left-width');
            return {horizontal: l+r, vertical: t+b, left: l, right: r, top: t, bottom: b, width: l+r, height: t+b};
        },

        getFlex: function(element) {
            element = $(element);
            var reg = new RegExp("\\bflex-\\d+\\b", "i");
            var klnames = element.attr("class");
            if (element.hasClass('flex')) {
                return 1;
            } else if (reg.test(klnames)) {
                var klass = reg.exec(klnames)+"";
                return parseFloat(klass.substring(5));
            }
            return 0;
        },

        isHorizontal: function(element) {
            element = $(element);
            return element.hasClass('hbox');
        },

        direction: function(element) {
            element = $(element);
            if (element.attr("dir") !== null) {
                return element.attr("dir");
            } else if (element.css("direction") !== "") {
                return element.css("direction");
            } else if ($('html').attr("dir") !== null) {
                return $('html').attr("dir");
            }
            return "rtl";
        },

        resize: function (element, width, height) {
            element = $(element);
            var children = element.children() /*.sort(function(a, b) {
                                                if ($(a).hasClass("anchor-right")) { return 1 } else if ($(a).hasClass("anchor-left")) { return 2 }; return 2;
                                                })*/;
            var childrenLength = children.length;
            if (width === undefined) {
                width = element.width();
                height = element.height();
            }

            if (childrenLength>0) {
                // element.css({position: "relative"});
                var horizontal = lr.isHorizontal(element);
                var elementLength = (horizontal ? width : height);

                if (lr.direction(element) === "rtl" && horizontal) {
                    children = children.reverse();
                }

                // Preprocessing dimensions values
                var child, index, dims;
                var flexSum = 0, fixedSum = 0;
                var lengths = [], flexes = [], borders = [];
                for (index=0;index<childrenLength;index++) {
                    child = $(children[index]);
                    if (child.css('display') !== 'none') {
                        borders[index] = lr.getBorderDimensions(child);
                        flexes[index]  = lr.getFlex(child);
                        if (flexes[index] === 0) {
                            lengths[index] = (horizontal ? child.width() : child.height());
                            fixedSum += lengths[index]
                        } else {
                            lengths[index] = 0;
                            flexSum += flexes[index];
                        }
                        fixedSum += (horizontal ? borders[index].width : borders[index].height);
                    }
                }

                // Redimensioning
                var w, h, childLeft=0, childTop=0, childLength=0, x=0;
                var flexUnit = (elementLength-fixedSum)/flexSum;
                var elementBorder = lr.getBorderDimensions(element);
                for (index=0; index<childrenLength; index++) {
                    child = $(children[index]);
                    if (child.css('display') !== 'none') {
                        if (flexes[index]>0) {
                            childLength = Math.floor(flexUnit*flexes[index]);
                        } else {
                            childLength = lengths[index];
                        }
                        if (flexSum>0) {
                            if (horizontal) {
                                w = childLength; /*-borders[index].horizontal*1;*/
                                h = height-borders[index].vertical*1;
                                childTop  = 0+lr.getNumericalStyle(child, 'margin-top')*1+lr.getNumericalStyle(element, 'padding-top')*1;
                                childLeft = x+lr.getNumericalStyle(element, 'padding-left')*1;
                            } else {
                                w = width-borders[index].horizontal*1;
                                h = childLength;/*-borders[index].vertical*1;*/
                                childTop  = x+lr.getNumericalStyle(element, 'padding-top')*1;
                                childLeft = 0+lr.getNumericalStyle(child, 'margin-left')*1+lr.getNumericalStyle(element, 'padding-left')*1;
                            }
                            if (child.css('overflow') === null) {
                                child.css({overflow: 'auto'});
                            }
                            child.css({width: w+'px', height: h+'px', position: 'absolute', top: childTop+'px', left: childLeft+'px'});
                            lr.resize(child, w,h);
                        }
                        x += childLength+(horizontal ? borders[index].width : borders[index].height);
                    }
                }
            }
            element.css({height: height+'px', width: width+'px'});
            element.removeClass("unresized");
            element.addClass("resized");
            return element;
        }
    };



    // Adds a plugin to jQuery to work with numerical values.
    $.fn.extractNumericalValue = function () {
        var element = $(this), value, option;
        if (element.is("select[data-value]")) {
            value = element.find('option:selected').attr('data-' + element.data('value'))
        } else if (element.is("select")) {
            value = element.find('option:selected').attr('value')
        } else if (element.is("input")) {
            value = element.val();
        } else {
            value = element.html();
        }
        if (value === undefined) {
            value = "0.0";
        }
        return value;
    }

    // Adds a plugin to jQuery to work with numerical values.
    $.fn.numericalValue = function (newValue) {
        var element = $(this.get(0)), value, commas, points;
        if (isNaN(newValue) || newValue === undefined) {
            // Get
            value  = element.extractNumericalValue();
            commas = value.split(/\,/g);
            points = value.split(/\./g)
            if (commas.length === 2 && points.length !== 2) { // Metric notation
                value = value.replace(/\./g, "").replace(/\,/g, ".");
            } else if (commas.length === 2 && points.length === 2 && commas[0].length > points[0].length) {
                value = value.replace(/\./g, "").replace(/\,/g, ".");
            } else {
                value = value.replace(/\,/g, "");
            }
            value = parseFloat(value.replace(/[^0-9\.]*/g, ''));
            /* if (element.is("input") && !isNaN(element.val())) {
               value = parseFloat(element.val());
               } else if (!isNaN(element.html())) {
               value = parseFloat(element.html());
               }*/
            if (isNaN(value)) {
                return 0;
            } else {
                return value;
            }
        } else {
            // Set
            if (element.is("input")) {
                element.val(toCurrency(newValue));
            } else {
                element.html(toCurrency(newValue));
            }
            return element;
        }
    };

    /*$.fn.isCalculationResult = function () {
      var elThis = $(this), result = true, calculations = ["sum", "mul"];
      for (var i; i < calculations.length ; i += 1) {
      cal = calculations[i];
      $("*[data-" + cal + "-of]").each(function () {
      $($(this).data(cal + "-of")).each(function () {
      if (this === elThis) { result = false; }
      });
      });
      if (result === false) { return result; }
      }
      return result;
      };*/

    $.fn.isCalculationResult = function () {
        var elThis = $(this), result = true;
        $("*[data-calculate][data-use]").each(function () {
            $($(this).data("use")).each(function () {
	        if (this === elThis) { result = false; }
            });
        });
        return result;
    };


    // Calculate result base on markup
    $.calculate = function () {
        var element = $(this), calculation = element.data("calculate"), use = element.data("use"), result = null, closest = element.data("use-closest"), round = parseInt(element.data("calculate-round"));
        if (use === null || use === undefined) {
            return element.numericalValue();
        }
        if (closest === null || closest === undefined) {
            use = $(use);
        } else {
            use = element.closest(closest).find(use);
        }
        if (calculation === "multiplication" || calculation === "mul") {
            result = 1;
            use.each(function () {
                result = result * $.calculate.call(this);
            });
        } else { // Sum by default
            result = 0;
            use.each(function () {
                result = result + $.calculate.call(this);
            });
        }

        if (!(isNaN(round))) {
			result = result.toFixed(round);
		}

        if (element.numericalValue() !== result) {
            element.numericalValue(result);
            element.trigger("emulated:change");
        }

        return result;
    };

    // Compute the sum of the elements
    $.fn.sum = function () {
        var result = 0;
        this.each(function () {
            result = result + $(this).numericalValue();
        });
        return result;
    };


    // Removes all nodes triggering event on them
    $.fn.deepRemove = function (event) {
        if (event === null || event === undefined) {
            event = "remove";
        }
        this.each(function() {
            var element = $(this), allChildren = element.find("*");
            allChildren.detach();
            allChildren.trigger(event);
            allChildren.remove();
            element.detach();
            element.trigger(event);
            element.remove();
        });
        return $;
    };


    // takes a GET-serialized string, e.g. first=5&second=3&a=b and sets input tags (e.g. input name="first") to their values (e.g. 5)
    $.unparam = function (params) {
        if (params === null || params === undefined) {
            return {};
        }
        // this small bit of unserializing borrowed from James Campbell's "JQuery Unserialize v1.0"
        params = params.split("&");

        var unserializedParams = {};
        $.each(params, function() {
            var properties = this.split("=");
            if((typeof properties[0] !== 'undefined') && (typeof properties[1] !== 'undefined')) {
	        unserializedParams[properties[0].replace(/\+/g, " ")] = properties[1].replace(/\+/g, " ");
            }
        });
        return unserializedParams;
    };

    $.buildURL = function (url, params) {
        var tempArray = url.split("?");
        var baseURL = tempArray[0];
        params = $.extend($.unparam(tempArray[1]), params);
        return baseURL + "?" + $.param(params);
    };



})(jQuery);
