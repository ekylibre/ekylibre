/* -*- Mode: Java; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2; coding: latin-1 -*- */
// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function trace(text) {
  $('side').innerHTML += text;
}


var resizeElementMethods = {
  
  getNumericalStyle: function(element, style) {
    element = $(element);
    var reg = new RegExp("[^\\.0-9]", "ig");
    var value = element.getStyle(style);
    if (value === null) {
      value = "0";
    }
    return Math.floor(new Number(value.replace(reg, "")));
  },

  getBorderDimensions: function(element) {
    element = $(element);
    var t = element.getNumericalStyle('padding-top')+element.getNumericalStyle('margin-top')+element.getNumericalStyle('border-top-width');
    var r = element.getNumericalStyle('padding-right')+element.getNumericalStyle('margin-right')+element.getNumericalStyle('border-right-width');
    var b = element.getNumericalStyle('padding-bottom')+element.getNumericalStyle('margin-bottom')+element.getNumericalStyle('border-bottom-width');
    var l = element.getNumericalStyle('padding-left')+element.getNumericalStyle('margin-left')+element.getNumericalStyle('border-left-width');
    return {horizontal: l+r, vertical: t+b};
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
  
  isHorizontal: function(element) {
    element = $(element);
    var h = true;
    if (element.getAttribute('orient') === 'vertical') {
      h = false;
    }
    return h;
  },
  

  resize: function(element, width, height) {
    var children = element.childElements();
    var children_length = children.length;
    if (width === undefined) { 
      var parent = element.ancestors()[0].getDimensions();
      width = parent.width; 
      if (height === undefined) { height = parent.height; }
      alert(width+"x"+height);
    }

    if (children_length>0) {
      element.makePositioned();
      var horizontal = element.isHorizontal();
      var element_length = (horizontal ? width : height);

      // Preprocessing dimensions values
      var child, index, border;
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
            fixedsum += lengths[index];
          } else {
            lengths[index] = 0;
            flexsum += flexes[index];
          }
        }
      }

      // Redimensioning
      var w, h, child_left=0, child_top=0, child_length=0, x=0, o;
      var flex_unit = (element_length-fixedsum)/flexsum;
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
              w = child_length-borders[index].horizontal*1;
              h = height-borders[index].vertical;
              child_top  = 0; 
              child_left = x;
            } else {
              w = width-borders[index].horizontal;
              h = child_length-borders[index].vertical*1;
              child_top  = x; 
              child_left = 0;
            }
            o=child.getStyle('overflow');
            if (null === o) {
              o = 'auto';
            }
            child.setStyle({width: w+'px', height: h+'px', overflow: o, position: 'absolute', top: child_top+'px', left: child_left+'px'});
            child.resize(w,h);
            /* child.setAttribute('resized', 'true'); */
          }
          x += child_length;
        }
      }
    }
    element.setStyle({height: height+'px', width: width+'px'});
    return element;
  }




};

Element.addMethods(resizeElementMethods);


var overlays = 0;



function _resize() {
  var dims   = document.viewport.getDimensions();
  var height = dims.height; 
  var width  = dims.width;
  var overlay = $('overlay');
  if (overlay != null) { 
    //   alert(overlay);
    overlay.setStyle({'width': width+'px', 'height': height+'px'});
  }
  $('body').resize(width,height);
}

function resize() {
  window.setTimeout('_resize()',300);
  return _resize();
}

function resize2() {
  window.setTimeout('_resize()',350);
  return _resize();
}


function openDialog(url) {
  var body   = document.getElementsByTagName("BODY")[0];
  var dims   = document.viewport.getDimensions();
  var height = dims.height; 
  var width  = dims.width;
  var overlay = $('overlay');
  if (overlay == null) {
    overlay = new Element('div', {id: 'overlay', style: 'z-index:1; position:absolute; top:0; left 0; width:'+width+'px; height: '+height+'px; opacity: 0.7'});
    /*  opacity: 0.8 */
    body.appendChild(overlay);
  }

  overlays += 1;
  var w = 0.8*width;
  var h = 0.9*height;
  var form_id = 'dialog'+overlays;
  var form = new Element('div', {id: form_id, flex: 1, 'class': 'dialog', style: ' z-index:'+(2+overlays*1)+'; position:absolute; left:'+((width-w)/2)+'px; top:'+((height-h)/2)+'px; width:'+w+'px; height: '+h+'px; opacity: 1'});
  body.appendChild(form);
  
  new Ajax.Request(url, {
      method: 'get',
        parameters: {dialog: form_id},
        onSuccess: function(response) {
        var form = $(form_id);
        form.innerHTML = response.responseText;
        return form.resize(w, h);
      }
  });
  return overlay;
}


function closeDialog(dialog) {
  dialog = $(dialog);
  dialog.remove();
  overlays -= 1;
  if (overlays == 0) {
    var overlay = $('overlay');
    if (overlay != null) {
      overlay.remove();
    }
  }
  return true;
}

function resizeDialog(dialog) {
  dialog = $(dialog);
  dialog.resize(dialog.getWidth(), dialog.getHeight());
}


function refreshList(select, source_url, request) {
  return new Ajax.Request(source_url, {
      method: 'get',
        parameters: {selected: request.responseJSON.id},
        onSuccess: function(response) {
        var list = $(select);
        list.innerHTML = response.responseText;
      }
  });
}

function refreshAutoList(dyli, request) {
  return dyliChange(dyli, request.responseJSON.id);
}

function dyliChange(dyli, id) {
  var dyli_hf =$(dyli);
  var dyli_tf =$(dyli+'_tf');
  
  return new Ajax.Request(dyli_hf.getAttribute('href'), {
      method: 'get',
        parameters: {id: id},
        onSuccess: function(response) {
        var obj = response.responseJSON;
        if (obj!= null) {
          dyli_hf.value = obj.hf_value;
          dyli_tf.value = obj.tf_value;
        }
      }
  });
}


function openHelp() {
  $('help-open').setStyle({display: 'none'});
  $('help').setStyle({display:'block'});
  return resize();
}


function closeHelp() {
  $('help-open').setStyle({display: 'block'});
  $('help').setStyle({display:'none'});
  return resize();
}

function openSide() {
  if ($('side').style.display=='none') {
    $('side').setStyle({display:'block'});
    $('side-open').setAttribute('id', 'side-close');
  } else {
    $('side').setStyle({display:'none'});
    $('side-close').setAttribute('id', 'side-open');
  }
  return resize();
}


function onLoading() {
  $('loading').setStyle({display: 'block'});
}

function onLoaded() {
  $('loading').setStyle({display: 'none'});
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



function toggleMenu(element) {
  var actions = $(element+'_actions');
  var title = $(element+'_title');
  var state;
  if (actions.style.display == "none") {
    actions.blindDown();
    title.removeClassName('closed');
    state = "true";
  } else {
    actions.blindUp();
    title.addClassName('closed');
    state = "false";
  }
  return state;
}


/* 
   Sum all the value in corresponding elements and update a target with its ID 
   Returns target
*/
function sum_all(css_rule, target_id) {
  var target = $(target_id);
  var sum = 0;
  $$(css_rule).each(function(element, index) { 
      var val;
      if (element.tagName.toLowerCase() == "input") {val = element.value; } 
      else { val = element.innerHTML; }
      if (!isNaN(val)) {sum += val*1;} 
    });
  sum = Math.round(sum*100)/100;
  if (target.tagName.toLowerCase() == "input") { target.value = sum; }
  else { target.innerHTML = sum; }
  return target;
}

/*
  
 */
function set_state(total_id, condition) {
  var total = $(total_id);
  if (condition) {
    total.addClassName("valid");
    total.removeClassName("invalid");
    balanced = true;
  } else {
    total.addClassName("invalid");
    total.removeClassName("valid");
    balanced = false;
  }
  return total;
}





function insert_into(input, repdeb, repfin, middle) {
  if(repfin == 'undefined') {repfin=' ';}
  if(middle == 'undefined') {middle=' ';}
  input.focus();
  /* pour l'Explorer Internet */
  if(typeof document.selection != 'undefined') {
	/* Insertion du code de formatage */
	var range = document.selection.createRange();
	var insText = range.text;
    if (insText.length <= 0) { insText = middle; }
	range.text = repdeb + insText + repfin;
	/* Ajustement de la position du curseur */
	range = document.selection.createRange();
	if (insText.length == 0) {
      range.move('character', -repfin.length);
	} else {
      range.moveStart('character', repdeb.length + insText.length + repfin.length);
	}
	range.select();
  }
  /* pour navigateurs plus récents basés sur Gecko*/
  else if(typeof input.selectionStart != 'undefined')	{
	/* Insertion du code de formatage */
	var start = input.selectionStart;
	var end = input.selectionEnd;
	var insText = input.value.substring(start, end);
    if (insText.length <= 0) { insText = middle; }
	input.value = input.value.substr(0, start) + repdeb + insText + repfin + input.value.substr(end);
	/* Ajustement de la position du curseur */
	var pos;
	if (insText.length == 0) {
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
	var pos;
	var re = new RegExp('^[0-9]{0,3}$');
	while(!re.test(pos)) {
      pos = prompt("Insertion à la position (0.." + input.value.length + ") :", "0");
	}
	if(pos > input.value.length) {
      pos = input.value.length;
	}
	/* Insertion du code de formatage */
	var insText = prompt("Veuillez entrer le texte à formater :");
    if (insText.length <= 0) { insText = middle; }
	input.value = input.value.substr(0, pos) + repdeb + insText + repfin + input.value.substr(pos);
  }
}



