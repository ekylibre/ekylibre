/* -*- Mode: Java; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2; coding: latin-1 -*- */
// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var XUL_ELEMENTS = ['box', 'vbox', 'hbox', 'splitter'];
var XUL_FLEX_ELEMENTS = ['box', 'vbox', 'hbox'];

function trace(text) {
  $('side').innerHTML += text;
}


var xulElementMethods = {
  getOuterDimensions: function(element) {
    element = $(element);
    var w = element.getWidth();
    var h = element.getHeight();
    alert(element.getNumericalStyle('padding-left')+','+
          element.getNumericalStyle('padding-right')+','+
          element.getNumericalStyle('padding')+','+
          element.getNumericalStyle('paddingLeft')+','+
          '-');
    /*
    w += element.getNumericalStyle('padding-left')+element.getNumericalStyle('padding-right');
    w += element.getNumericalStyle('margin-left')+element.getNumericalStyle('margin-right');
    w += element.getNumericalStyle('border-left-width')+element.getNumericalStyle('border-right-width');
    h += element.getNumericalStyle('padding-top')+element.getNumericalStyle('padding-bottom');
    h += element.getNumericalStyle('margin-top')+element.getNumericalStyle('margin-bottom');
    h += element.getNumericalStyle('border-top-width')+element.getNumericalStyle('border-bottom-width');
    */
    return {width: w, height: h};
  },
  
  getBorderDimensions: function(element) {
    element = $(element);
    var t = element.getNumericalStyle('padding-top')+element.getNumericalStyle('margin-top')+element.getNumericalStyle('border-top-width');
    var r = element.getNumericalStyle('padding-right')+element.getNumericalStyle('margin-right')+element.getNumericalStyle('border-right-width');
    var b = element.getNumericalStyle('padding-bottom')+element.getNumericalStyle('margin-bottom')+element.getNumericalStyle('border-bottom-width');
    var l = element.getNumericalStyle('padding-left')+element.getNumericalStyle('margin-left')+element.getNumericalStyle('border-left-width');
    return {horizontal: l+r, vertical: t+b};
  },
  
  getNumericalStyle: function(element, style) {
    element = $(element);
    var reg = new RegExp("[^\\.0-9]", "ig");
    var value = element.getStyle(style).replace(reg, "");
    return Math.floor(value*1);
  },

  xul: function(element) {
    element = $(element);
    return element.getAttribute('xul');
  },

  flex: function(element,def) {
    element = $(element);
    var flex = element.getAttribute('flex');
    if (isNaN(flex) || flex === null) {
      if (isNaN(def) || def === null) {
        return 0;
      } else {
        return def;
      }
    } else {
      return flex*1;
    }
  },
  
  isXUL: function(element) {
    element = $(element);
    var xul = element.getAttribute('xul');
    var inArray = false;
    for(var i=0;i<XUL_ELEMENTS.length;i++) {
      if (xul === XUL_ELEMENTS[i]) {
        inArray = true;
      }
    }
    return inArray;
  },
  
  isFlexible: function(element) {
    element = $(element);
    var xul = element.getAttribute('xul');
    var inArray = false;
    if (element.tagName !== 'DIV' && element.tagName !== 'BODY') {
      return false;
    }
    for(var i=0;i<XUL_FLEX_ELEMENTS.length;i++) {
      if (xul === XUL_FLEX_ELEMENTS[i]) {
        inArray = true;
      }
    }
    return inArray;
  },

  isHorizontal: function(element) {
    element = $(element);
    var h = true;
    if (element.xul() === 'vbox') {
      h = false;
    } else if (element.xul() === 'hbox') {
      h = true;
    } else if (element.getAttribute('orient') === 'vertical') {
      h = false;
    }
    return h;
  },
  
  resizeTo: function(element,width,height) {
    var children = element.childElements();
    trace(element.tagName);
    if (children.length>0) {
      // Preprocessing dimensions values
      var child;
      var flex,dims,d;
      var totalFlex   = 0;
      var totalWidth  = 0;
      var totalHeight = 0;
      
      for (d=0;d<children.length;d++) {
        child = children[d];
        if (child.isXUL()) {
          totalFlex += child.flex();
        } else {
          dims = child.getOuterDimensions();
          totalWidth  += dims.width;
          totalHeight += dims.height;
        }
      }
      if (totalFlex>=1) {
        trace('/'+totalFlex+'{');
        // Redimensioning
        var w,h;
        var horizontal = element.isHorizontal();
        var kh = (height-10-totalHeight)/totalFlex;
        var kw = (width-10-totalWidth)/totalFlex;
        for (d=0;d<children.length;d++) {
          child = children[d];
          if (child.isFlexible()) {
            flex = child.flex();
            if (horizontal) {
              h = height;//element.getHeight();
              w = kw*flex;
            } else {
              h = kh*flex;
              w = width;//element.getWidth();
            }
            child.resizeTo(w,h);
          }
        }
        trace('}');
      }
    }
    element.setStyle({height: height+'px', width: width+'px'});
    //    element.innerHTML += '<br/>'+width+' x '+height;
    trace('! ');
    return element;
  },

  resize: function(element,width,height) {
    var children = element.childElements();
    var children_length = children.length;
    if (children_length>0) {
      element.makePositioned();
      var horizontal = element.isHorizontal();
      var length = (horizontal ? width : height);

      // Preprocessing dimensions values
      var child, index, border;
      var flexsum = 0;
      var fixedsum = 0;
      var lengths = [], flexes = [], borders = [];
      for (index=0;index<children_length;index++) {
        child = children[index];
        borders[index] = child.getBorderDimensions();
        flexes[index] = child.flex();
        lengths[index] = 0;
        if (flexes[index] !== 0) {
          flexsum += flexes[index];
        } else {
          dims = child.getDimensions();
          lengths[index] = (horizontal ? dims.width : dims.height);
          fixedsum += lengths[index];
        }
      }

      // Redimensioning
      var w,h,l,x=0;
      var k = (length-fixedsum)/flexsum;
      for (index=0;index<children_length;index++) {
        child = children[index];
        w = width-borders[index].horizontal;
        h = height-borders[index].vertical;
        if (flexes[index]>0) {
          l = k*flexes[index];
        } else {
          l = lengths[index];
        }
        if (horizontal) {
          child.setStyle({width: (l-borders[index].horizontal)+'px', height: h+'px', overflow: 'auto', position: 'absolute', top: '0px', left: x+'px'});
        } else {
          child.setStyle({width: w+'px', height: (l-borders[index].vertical)+'px', overflow: 'auto', position: 'absolute', top: x+'px', left: '0px'});
        }
        x += l;
        //        trace('> ('+x+', '+l+') ');
        // child.resizeTo(w,h);
      }
      //      trace(' = '+length+' !<br/>');
    }
    element.setStyle({height: height+'px', width: width+'px'});
    //    element.innerHTML += '<br/>'+width+' x '+height;
    return element;
  }




};

Element.addMethods(xulElementMethods);




function _resize() {
  var dims   = document.viewport.getDimensions();
  var height = dims.height-21;
  var width  = dims.width;
  $('columns').resize(width,height);
}

function resize() {
  window.setTimeout('_resize()',300);
  _resize();
  /*  _resize();*/
}

function toggleHelp() {
  var close =  $('help-close').getStyle('display');
  if (close === 'none') {
    $('help-open').setStyle({display: 'none'});
    $('help-close').setStyle({display: 'block'});
  } else {
    $('help-open').setStyle({display: 'block'});
    $('help-close').setStyle({display: 'none'});
    Element.remove($('help'));
  }
  resize();
}


function windowResize() {
  var dims   = document.viewport.getDimensions();
  var body   = getBody();
  var height = dims.height;
  var width  = dims.width;
  trace('<br/><strong>'+width+' x '+height+'</strong><br/>');
  body.resizeTo(width,height);
  //  elementResize(body,width,height);
}

function getBody() {
  return document.getElementsByTagName("BODY")[0];
}



function followTheMouse(element, event) {
  element = $(element);
  //  alert(event.clientX);
  element.setStyle({left: event.clientX});
}