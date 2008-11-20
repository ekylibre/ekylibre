/* -*- Mode: Java; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2; coding: latin-1 -*- */
// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var XUL_ELEMENTS = ['box', 'vbox', 'hbox', 'splitter'];
var XUL_FLEX_ELEMENTS = ['box', 'vbox', 'hbox'];

function trace(text) {
  $('result').innerHTML += text;
}


var xulElementMethods = {
  getOuterDimensions: function(element) {
    element = $(element);
    var w = element.getWidth();
    var h = element.getHeight();
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

  flex: function(element) {
    element = $(element);
    var flex = element.getAttribute('flex');
    if (isNaN(flex)) {
      return 0;
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
              h = height//element.getHeight();
              w = kw*flex;
            } else {
              h = kh*flex;
              w = width//element.getWidth();
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
  }

};

Element.addMethods(xulElementMethods);


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

