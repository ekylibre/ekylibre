/* -*- Mode: Java; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2; coding: latin-1 -*- */
/*jslint browser: true */

function _resize() {
  var dims   = document.viewport.getDimensions();
  var height = dims.height; 
  var width  = dims.width;
  var overlay = $('overlay');
  if (overlay !== null) { 
    overlay.setStyle({'width': width+'px', 'height': height+'px'});
  }
  $$('.dialog').each(function(element, index) { 
      var w = 0.9*width;
      var h = 0.9*height;
      element.setStyle({left: ((width-w)/2)+'px', top: ((height-h)/2)+'px'});
      element.resize(w, h);
    });
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


function toggleHelp(help, show, resized) {
  toggleElement(help, show, help+'-open');
  if (resized === undefined) {
    return resize();
  } else {
    return $(resized).resize();
  }
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
    $('main').addClassName('with-side');
  } else {
    $('side').setStyle({display:'none'});
    $('side-close').setAttribute('id', 'side-open');
    $('main').removeClassName('with-side');
  }
  return resize();
}


function onLoading() {
  $('loading').setStyle({display: 'block'});
}

function onLoaded() {
  $('loading').setStyle({display: 'none'});
}

function toggleElement(element, show, reverse_element) {
  element = $(element);
  if (show === null) { 
    show = (element.style.display == "none"); 
  }
  if (show) {
    element.show();
    if (reverse_element !== undefined) {
      $(reverse_element).hide();
    }
  } else {
    element.hide();
    if (reverse_element !== undefined) {
      $(reverse_element).show();
    }
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
  else if(typeof input.selectionStart != 'undefined')	{
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



