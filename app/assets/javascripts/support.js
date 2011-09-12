/* -*- Mode: Javascript; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2; coding: latin-1 -*- */
/*jslint browser: true */



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



function format(valeur, decimal, separateur) {
    var deci=Math.round(Math.pow(10, decimal)*(Math.abs(valeur)-Math.floor(Math.abs(valeur))));
    var val=Math.floor(Math.abs(valeur));
    if ((decimal===0)||(deci==Math.pow(10,decimal))) {val=Math.floor(Math.abs(valeur)); deci=0;}
    var valFormat=val+"";
    var nb=valFormat.length;
    for (var i=1;i<4;i++) {
	if (val>=Math.pow(10,(3*i))) {
	    valFormat=valFormat.substring(0,nb-(3*i))+separateur+valFormat.substring(nb-(3*i));
	}
    }
    if (decimal>0) {
	var decim="";
	for (var j=0;j<(decimal-deci.toString().length);j++) {decim+="0";}
	deci=decim+deci.toString();
	valFormat=valFormat+"."+deci;
    }
    if (parseFloat(valeur)<0) {valFormat="-"+valFormat;}
    return valFormat;
}

/*
  Display a number with money presentation
*/
function toCurrency(value) {
    return format(value, 2, "");
}






function ($) {
    

} (jQuery);