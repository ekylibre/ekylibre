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
  

  resize: function(element,width,height) {
    var children = element.childElements();
    var children_length = children.length;
    if (children_length>0) {
      element.makePositioned();
      var horizontal = element.isHorizontal();
      var length = (horizontal ? width : height);

      // Preprocessing dimensions values
      var child, index, border;
      var flexsum = 0, fixedsum = 0;
      var lengths = [], flexes = [], borders = [];
      for (index=0;index<children_length;index++) {
        child = children[index];
        if (child.getStyle('display') !== 'none') {
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
      }

      // Redimensioning
      var w,h,l=0,t=0,s=0,x=0,o;
      var k = (length-fixedsum)/flexsum;
      for (index=0;index<children_length;index++) {
        child = children[index];
        if (child.getStyle('display') !== 'none') {
          w = width-borders[index].horizontal;
          h = height-borders[index].vertical;
          if (flexes[index]>0) {
            s = k*flexes[index];
          } else {
            s = lengths[index];
          }
          if (horizontal) {
            w = s-borders[index].horizontal*1;
            t = 0; 
            l = x;
          } else {
            h = s-borders[index].vertical*1;
            t = x; 
            l = 0;
          }
          /*
          child.setStyle({width: w+'px', height: h+'px', overflow: 'auto', position: 'absolute', top: t+'px', left: l+'px'});
          child.setAttribute('test',x+' '+s+' '+lengths[index]+' ');
          */
          
          if (flexes[index]>0 || child.getAttribute('flexy') === 'true') {
            o=child.getStyle('overflow');
            if (null === o) {
              o = 'auto';
            }
            child.setStyle({width: w+'px', height: h+'px', overflow: o, position: 'absolute', top: t+'px', left: l+'px'});
            child.resize(w,h);
            /* child.setAttribute('resized', 'true'); */
          } else {
            /* child.setStyle({position: 'absolute', top: t+'px', left: l+'px'}); */
          }
          
          x += s;
        }
      }
    }
    element.setStyle({height: height+'px', width: width+'px'});
    return element;
  }




};

Element.addMethods(xulElementMethods);




function _resize() {
  var dims   = document.viewport.getDimensions();
  var height = dims.height; /*-25;*/
  var width  = dims.width;
  $('body').resize(width,height);
}

function resize() {
  window.setTimeout('_resize()',300);
  _resize();
  /*  _resize();*/
}

function resize2() {
  window.setTimeout('_resize()',350);
  _resize();
  /*  _resize();*/
}

function openHelp() {
  $('help-open').setStyle({display: 'none'});
  $('help').setStyle({display:'block'});
  resize();
}


function closeHelp() {
  $('help-open').setStyle({display: 'block'});
  $('help').setStyle({display:'none'});
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

function onLoading() {
  $('loading').setStyle({display: 'block'});
}

function onLoaded() {
  $('loading').setStyle({display: 'none'});
}