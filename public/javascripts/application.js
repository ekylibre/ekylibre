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
    var value = element.getStyle(style);
    if (value === null) {
      value = "0";
    }
    return Math.floor(new Number(value.replace(reg, "")));
    /*if (value !== null) {
      return Math.floor(new Number(value.replace(reg, "")));
      }*/
  },
  
  xul: function(element) {
    element = $(element);
    return element.getAttribute('xul');
  },

  getFlex: function(element) {
    element = $(element);
    var f = element.getAttribute("flex");
    if (isNaN(f) || f === null) {
      return 0;
    } else {
      return new Number(f);
    }
    return 0;
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
        // alert("Child: "+child.id+" ("+child.getStyle('display')+")");
        if (child.getStyle('display') !== 'none') {
          borders[index] = child.getBorderDimensions();
          // alert("Child border : "+borders[index]);
          flexes[index] = child.getFlex();
          //alert("Child flex : "+flexes[index]);
          lengths[index] = 0;
          //alert("B>>"+index+" - "+flexes[index]);
          if (flexes[index] !== 0) {
            //alert("C>>"+index);
            flexsum += flexes[index];
          } else {
            //alert("D>>"+index);
            dims = child.getDimensions();
            lengths[index] = (horizontal ? dims.width : dims.height);
            fixedsum += lengths[index];
          }
          // alert("E>>"+index);
        }
      }

      // alert("FIN");

      // Redimensioning
      var w,h,l=0,t=0,s=0,x=0,o;
      var k = (length-fixedsum)/flexsum;
      for (index=0;index<children_length;index++) {
        child = children[index];
        if (child.getStyle('display') !== 'none') {
          w = width-borders[index].horizontal;
          h = height-borders[index].vertical;
          if (flexes[index]>0) {
            s = Math.floor(k*flexes[index]);
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

function openSide() {
  if ($('side').style.display=='none') {
    $('side').setStyle({display:'block'});
    $('side-open').setAttribute('id', 'side-close');
  } else {
    $('side').setStyle({display:'none'});
    $('side-close').setAttribute('id', 'side-open');
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

function onLoading() {
  $('loading').setStyle({display: 'block'});
}

function onLoaded() {
  $('loading').setStyle({display: 'none'});
}










/*

var AutoJumpToNextOnLength = Behavior.create({
  initialize: function(inputLength)
  {
    this.inputLength = inputLength;
    this.element.setAttribute('autocomplete','off');
    this.keyRange = $R(48, 90).toArray().concat($R(96, 105).toArray()); // all alphanumeric characters
  },
  onkeydown: function(e)
  {
    alert('OK');
    // Detect if there is selected text, if there is remove that selected text now.
    selection = this.element.getValue().substring(this.element.selectionStart, this.element.selectionEnd).length
    
    if (selection == 0) {
	  // Stops extra characters being entered    
	  if (this.keyRange.include(e.keyCode)) {
        return !(this.element.getValue().length >= this.inputLength);
	  } else {
        return true;
	  }
    }
  },
  onkeyup: function(e)
  {
    // Detect if there is selected text, if there is remove that selected text now.
    selection = this.element.getValue().substring(this.element.selectionStart, this.element.selectionEnd).length
    
    if (selection == 0) {
      
      if (this.keyRange.include(e.keyCode) && (this.element.getValue().length == this.inputLength)) {
        try {
          this.element.next().focus();
          this.element.next().select();
        } catch(err) {
          // No next field 
          return false;
        }
      }
    }
  }
  });

Event.addBehavior({'.day_field, .month_field, .hour_field, .minute_field, second_field' : AutoJumpToNextOnLength(2)});
Event.addBehavior({'.year_field' : AutoJumpToNextOnLength(4)});

*/

var numericKeys = $R(96, 105).toArray();
var separatorKeys = [111, 191, 109, 190, 188];


function autoTabDown(e) {
  //  $('test').innerHTML += ' [D] ';
  var element = e.element();
  element.setAttribute('selected','true');
  element.setAttribute('previous',element.getValue());
  return false;
}

function autoTabUp(e) {
  //  if (!numericRange.include(e.keyCode) && (e.element.getValue().length == e.element.getAttribute('size'))) {
  var element = e.element();
  /*
  $('test').innerHTML += '['; 
  $('test').innerHTML += 'U:'; 
  $('test').innerHTML += element.getValue()+',';
  $('test').innerHTML += element.getAttribute('size')+' '+element.getValue().length;
  $('test').innerHTML += '::'+e.keyCode; 
  $('test').innerHTML += '::'+separatorKeys.indexOf(e.keyCode);
  $('test').innerHTML += '::'+separatorKeys.indexOf(e.keyCode);
  $('test').innerHTML += '] '; 
*/
  if (isNaN(element.getValue()))
    element.value = element.getAttribute('previous');
  else {
    if (element.getValue()<1)
      element.value = element.getAttribute('previous');
  }
  
  // || element.getValue().length*1 == element.getAttribute('size')*1) && element.getAttribute('selected') !== 'true'
  if (separatorKeys.indexOf(e.keyCode)>=0) {
    //  if (element.getValue().length*1 == element.getAttribute('size')*1) {
    if (separatorKeys.indexOf(e.keyCode)>=0 && element.getValue().length>element.getAttribute('previous').length)
      element.value = element.getAttribute('previous');
    try {
      element.next().activate();
      return true;
    } catch(err) {
      // No next field 
      return false;
    }
  }
  element.setAttribute('selected','false');

  return false;
}


function addAutoTab(elementArray) {
  //  $('test').innerHTML += '>>';
  //  alert(elementArray);
  for (var index = 0, len = elementArray.length; index < len; ++index) {
    var item = elementArray[index];
    //item.observe('keydown', autoTab);
    item.observe('keydown', autoTabDown);
    item.observe('keyup', autoTabUp);
  }
  return true;
}

function initTab() {
  //  addAutoTab($$('.day_field', '.month_field', '.hour_field', '.minute_field', '.second_field', '.year_field'));
}

function toggleElement(element) {
  var dom;
  dom = $(element);
  if (dom.style.display == "none") {
    dom.blindDown();
  } else {
    dom.blindUp();
  }
  return false;
}