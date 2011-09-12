
var resizeElementMethods = {
    
    getNumericalStyle: function(element, style) {
	element = $(element);
	var reg = new RegExp("[^\\.0-9]", "ig");
	var value = element.getStyle(style);
	if (value === null) {
	    value = "0";
	}
	return Math.floor(parseFloat(value.replace(reg, "")));
    },

    getBorderDimensions: function(element) {
	element = $(element);
	var t = element.getNumericalStyle('padding-top')+element.getNumericalStyle('margin-top')+element.getNumericalStyle('border-top-width');
	var r = element.getNumericalStyle('padding-right')+element.getNumericalStyle('margin-right')+element.getNumericalStyle('border-right-width');
	var b = element.getNumericalStyle('padding-bottom')+element.getNumericalStyle('margin-bottom')+element.getNumericalStyle('border-bottom-width');
	var l = element.getNumericalStyle('padding-left')+element.getNumericalStyle('margin-left')+element.getNumericalStyle('border-left-width');
	return {horizontal: l+r, vertical: t+b, left: l, right: r, top: t, bottom: b, width: l+r, height: t+b};
    },
    
    getFlex: function(element) {
	element = $(element);
	var reg = new RegExp("\\bflex-\\d+\\b", "i");
	var klnames = element.className;
	if (element.hasClassName('flex')) {
	    return 1;
	} else if (reg.test(klnames)) {
	    var klass = reg.exec(klnames)+"";
	    return parseFloat(klass.substring(5));
	}
	return 0;
    },
    
    isHorizontal: function(element) {
	element = $(element);
	return element.hasClassName('hbox');
    },

    direction: function(element) {
	element = $(element);
	if (element.style.direction !== "") {
	    return element.style.direction;
	} else if (element.getAttribute("dir") !== null) {
	    return element.getAttribute("dir");
	} else if ($$('html')[0].getAttribute("dir") !== null) {
	    return $$('html')[0].getAttribute("dir");
	}
	return "rtl";
    },

    resize: function(element, width, height) {
	var children = element.childElements().sortBy(function(s) {if (s.hasClassName("anchor-right")) {return 2} else if (s.hasClassName("anchor-left")) {return 1}; return 1;});
	var children_length = children.length;
	if (width === undefined) { 
	    /*
              var parent = element.ancestors()[0].getDimensions();
              width = parent.width; 
              if (height === undefined) { height = parent.height; }
              alert(width+"x"+height);*/
	    width = element.getWidth();
	    height = element.getHeight();
	}


	if (children_length>0) { 
	    element.makePositioned();
	    var horizontal = element.isHorizontal();
	    var element_length = (horizontal ? width : height);

	    if (element.direction() == "rtl" && horizontal) {
		children = children.reverse();
	    }

	    // Preprocessing dimensions values
	    var child, index, dims;
	    var flexsum = 0, fixedsum = 0;
	    var lengths = [], flexes = [], borders = [];
	    for (index=0;index<children_length;index++) {
		child = children[index];
		if (child.getStyle('display') !== 'none') {
		    borders[index] = child.getBorderDimensions();
		    flexes[index]  = child.getFlex();
		    if (flexes[index] === 0) {
			dims = child.getDimensions();
			lengths[index] = (horizontal ? dims.width : dims.height);
			fixedsum += lengths[index]
		    } else {
			lengths[index] = 0;
			flexsum += flexes[index];
		    }
		    fixedsum += (horizontal ? borders[index].width : borders[index].height);
		}
	    }

	    // Redimensioning
	    var w, h, child_left=0, child_top=0, child_length=0, x=0;
	    var flex_unit = (element_length-fixedsum)/flexsum;
	    var element_border = element.getBorderDimensions();
	    for (index=0;index<children_length;index++) {
		child = children[index];
		if (child.getStyle('display') !== 'none') {
		    if (flexes[index]>0) {
			child_length = Math.floor(flex_unit*flexes[index]);
		    } else {
			child_length = lengths[index];
		    }
		    if (flexsum>0) {
			if (horizontal) {
			    w = child_length; /*-borders[index].horizontal*1;*/
			    h = height-borders[index].vertical*1;
			    child_top  = 0+child.getNumericalStyle('margin-top')*1+element.getNumericalStyle('padding-top')*1;
			    child_left = x+element.getNumericalStyle('padding-left')*1;
			} else {
			    w = width-borders[index].horizontal*1;
			    h = child_length;/*-borders[index].vertical*1;*/
			    child_top  = x+element.getNumericalStyle('padding-top')*1; 
			    child_left = 0+child.getNumericalStyle('margin-left')*1+element.getNumericalStyle('padding-left')*1;
			}
			if (child.getStyle('overflow') === null) {
			    child.setStyle({overflow: 'auto'});
			}
			child.setStyle({width: w+'px', height: h+'px', position: 'absolute', top: child_top+'px', left: child_left+'px'});
			child.resize(w,h);
		    }
		    x += child_length+(horizontal ? borders[index].width : borders[index].height);
		}
	    }
	}
	element.setStyle({height: height+'px', width: width+'px'});
	element.removeClassName("unresized");
	element.addClassName("resized");
	return element;
    }, 

    unresize: function(element) {
	element = $(element);
	var children = element.childElements();
	var children_length = children.length;
	
	/*    $('side').innerHTML += ""+element.id+"/"+element.tagName+" ("+children_length+")<br/>"*/
	if (children_length>0) { 
	    /* element.undoPositioned();*/

	    // Redimensioning
	    var index, child;
	    for (index=0;index<children_length;index++) {
		child = children[index];
		if (child.hasClassName('resized')) {
		    child.unresize();
		}
	    }
	}
	element.setStyle({height: '', width: '', position: '', top: '', left: ''});
	/*element.morph({height: 'auto', width: 'auto', position: 'static', top: 'auto', left: 'auto'});*/
	/*element.setStyle({height: 'auto', width: 'auto', position: 'static', top: 'auto', left: 'auto'})*/
	element.removeClassName("resized");
	element.addClassName("unresized");

	return element;
    }

};

Element.addMethods(resizeElementMethods);


function _resize() {
    var body = $('body');
    var dims   = document.viewport.getDimensions();
    var height = dims.height; 
    var width  = dims.width;
    var overlay = $('overlay');
    if (overlay !== null) { 
	      overlay.setStyle({'width': width+'px', 'height': height+'px'});
    }
    $$('.dialog').each(function(element, index) { 
	      var ratio;
	      try { ratio=parseFloat(element.getAttribute("data-ratio")); }
	      catch(error) { ratio=0.9; }
	      var w = element.getWidth();
	      var h = element.getHeight();
	      if (ratio > 0) {
            w = ratio*width;
            h = ratio*height;
            element.resize(w, h);
	      }
	      element.setStyle({left: ((width-w)/2)+'px', top: ((height-h)/2)+'px'});
    });
    if (!body.hasClassName('resizable')) { return 0; }
    body.resize(width, height);
}

function resize() {
    window.setTimeout('_resize()', 300);
    return _resize();
}

function makeResizable() {
    var body = $('body');
    resize();
    body.removeClassName('unresizable');
    body.addClassName('resizable');
    return true;
}

function undoResizable() {
    var body = $('body');
    body.unresize();
    body.removeClassName('resizable');
    body.addClassName('unresizable');
    return true;
}

function resize2() {
    window.setTimeout('_resize()',350);
    return _resize();
}





(function() {

    document.on("click", "#side-splitter[data-toggle]", function(event, element) {
	      var splitted;
	      if (toggleElement("side")) {
            splitted = 0;
            element.removeClassName("closed");
	      } else {
            splitted = 1;
            element.addClassName("closed");
	      }
	      resize();
	      /* Put request with url in param*/
	      var url = element.readAttribute('data-toggle');
	      new Ajax.Request(url, { method: "post", parameters: {splitted: splitted} });
	      event.stop();
    });


    document.on("click", ".tabbox > .tabs > .tab[data-tabbox-index]", function(event, element) {
	      var tabbox = element.ancestors()[1];
	      if (tabbox !== null) {
	          tabbox.select('.tabs > .tab.current', '.tabpanels > .tabpanel.current').each(function (item) {
		            item.removeClassName('current');
	          });
	          var index = element.readAttribute('data-tabbox-index');
	          if (index !== null) {
		            tabbox.select('.tabs > .tab[data-tabbox-index="'+index+'"]', '.tabpanels > .tabpanel[data-tabbox-index="'+index+'"]').each(function (item) {
		                item.addClassName('current');
		            });
	          }
	          var url = tabbox.readAttribute("data-tabbox");
	          if (url !== null) {
		            new Ajax.Request(url, {
		                method: 'get',
		                parameters: {index: index}
		            });
	          }
	      }
	      event.stop();
    });


    

})();
