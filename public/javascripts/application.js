/* -*- Mode: Java; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2; coding: latin-1 -*- */
/*jslint browser: true */


function toggleElement(element, show, reverse_element) {
  element = $(element);
  if (show === null || show === undefined) { 
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
      try { ratio=parseFloat(element.getAttribute("ratio")); }
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


function toggleHelp(help, show, resized) {
  toggleElement(help, show, help+'-open');
  if ($('help').style.display=='none') {
    $('main').removeClassName('with-help');
  } else {
    $('main').addClassName('with-help');
  }
  if (resized === undefined) {
    return resize();
  } else {
    return $(resized).resize();
  }
}

function openHelp() {
  $('help-open').setStyle({display: 'none'});
  $('help').setStyle({display:'block'});
  $('main').addClassName('with-help');
  return resize();
}


function closeHelp() {
  $('help-open').setStyle({display: 'block'});
  $('help').setStyle({display:'none'});
  $('main').removeClassName('with-help');
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

function toggleCheckBox(element) {
  element = $(element);
  if (element !== null) {
    element.checked = !element.checked;
    element.onclick();
  }
  return element.checked;
}



function format(valeur, decimal, separateur) {
  // formate un chiffre avec 'decimal' chiffres après la virgule et un separateur
  var deci=Math.round(Math.pow(10, decimal)*(Math.abs(valeur)-Math.floor(Math.abs(valeur))));
  var val=Math.floor(Math.abs(valeur));
  if ((decimal===0)||(deci==Math.pow(10,decimal))) {val=Math.floor(Math.abs(valeur)); deci=0;}
  var val_format=val+"";
  var nb=val_format.length;
  for (var i=1;i<4;i++) {
    if (val>=Math.pow(10,(3*i))) {
      val_format=val_format.substring(0,nb-(3*i))+separateur+val_format.substring(nb-(3*i));
    }
  }
  if (decimal>0) {
    var decim="";
    for (var j=0;j<(decimal-deci.toString().length);j++) {decim+="0";}
    deci=decim+deci.toString();
    val_format=val_format+"."+deci;
  }
  if (parseFloat(valeur)<0) {val_format="-"+val_format;}
  return val_format;
}


/*
  Display a number with money presentation
*/
function toCurrency(value) {
  return format(value, 2, "");
}

/* 
   Sum all the value in corresponding elements and update a target with its ID 
   Returns target
*/
function sumAll(css_rule, target_id) {
  var target = $(target_id);
  var sum = 0;
  var reg = new RegExp(",", "ig");
  var reg2 = new RegExp("[^0-9\\.]+", "ig");
  $$(css_rule).each(function(element, index) { 
      var val;
      if (element.tagName.toLowerCase() == "input") {val = element.value; } 
      else { val = element.innerHTML; }
      val = val.replace(reg, ".").replace(reg2, "");
      if (!isNaN(val)) {sum += val*1;} 
    });
  sum = toCurrency(sum);
  if (target.tagName.toLowerCase() == "input") { target.value = sum; }
  else { target.innerHTML = sum; }
  return target;
}


function sum_all(css_rule, target_id) {
  return sumAll(css_rule, target_id);
}

function compute(element) {
  element = $(element);
  var total=0;
  var sum_class = element.readAttribute('sum-of');
  var mul_class = element.readAttribute('mul-of');
  var computed = 1;
  if (sum_class !== null) {
    $$('.'+sum_class).each(function(item) { total = total*1+compute(item)*1; });
  } else if (mul_class !== null) {
    $$('.'+mul_class).each(function(item) { 
        if (total == 0) { total = 1; }
        total = total*compute(item); 
      });
  } else {
    computed = 0;
    if (element.tagName.toLowerCase() == "input" && !isNaN(element.value)) { 
      total = parseFloat(element.value); 
    } else if (!isNaN(element.innerHTML)) {
      total = parseFloat(element.innerHTML);
    }
  }
  if (isNaN(total)) {
    total = 0;
  }

  if (computed == 1) {
    if (element.tagName.toLowerCase() == "input") { 
      element.value = toCurrency(total); 
    } else { 
      element.innerHTML = toCurrency(total); 
    }
  }
  return total;
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


var expirationTimer;

function reconnect() {
  var body = $('body');
  var href = body.getAttribute('data-timeout-href');
  if (href !== null && href !== undefined) {
    openDialog(href, 0);
  }
}

function unexpire() {
  var body = $('body');
  try { window.clearTimeout(expirationTimer); }
  catch (error) { };
  if (!isNaN(body.getAttribute('data-timeout'))) {
    var duration = parseFloat(body.getAttribute('data-timeout'))*1000;
    expirationTimer = window.setTimeout(reconnect, duration);
  }
}


Event.observe(window, "dom:loaded", resize);
Event.observe(window, "resize", resize);

Event.observe(window, "dom:loaded", unexpire);
Event.observe(window, "ajax:complete", unexpire);
