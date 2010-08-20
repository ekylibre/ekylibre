/* -*- Mode: Java; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2; coding: latin-1 -*- */


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
      /*alert('OK 2 '+element);*/
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
      /* alert('OK 3 '+element); */
      /*if (element.getAttribute("id") == "side") { alert(width); }*/

      // Redimensioning
      var w, h, child_left=0, child_top=0, child_length=0, x=0;
      var flex_unit = (element_length-fixedsum)/flexsum;
      var element_border = element.getBorderDimensions();
      /*(horizontal ? element.getNumericalStyle('padding-left') : element.getNumericalStyle('padding-top'))*/
      /*alert(flex_unit);*/
      for (index=0;index<children_length;index++) {
        child = children[index];
        if (child.getStyle('display') !== 'none') {
          if (flexes[index]>0) {
            child_length = Math.floor(flex_unit*flexes[index]);
          } else {
            child_length = lengths[index];
          }
          if (flexsum>0) {
            /*if (child.getAttribute("id") == "side") { alert(child.getDimensions().width); }*/
            if (horizontal) {
              w = child_length; /*-borders[index].horizontal*1;*/
              h = height-borders[index].vertical*1;
              child_top  = 0+child.getNumericalStyle('margin-top')*1+element.getNumericalStyle('padding-top');
              child_left = x;
            } else {
              w = width-borders[index].horizontal*1;
              h = child_length;/*-borders[index].vertical*1;*/
              child_top  = x; 
              child_left = 0+child.getNumericalStyle('margin-left')*1+element.getNumericalStyle('padding-left');
            }
            /*if (child.getAttribute("id") == "side") { alert( w ); }*/
            /*w -= borders[index].horizontal*1;
              h -= borders[index].vertical*1;*/
            /* child_top  += element_border.top; /*element.getNumericalStyle('padding-top');*/
            /* child_left += element_border.left; /*element.getNumericalStyle('padding-left');*/
            /*
            child_top  += child.getNumericalStyle('margin-top')*1+element.getNumericalStyle('padding-top');
            child_left += child.getNumericalStyle('margin-left')*1+element.getNumericalStyle('padding-left');
            */
            if (child.getStyle('overflow') === null) {
              child.setStyle({overflow: 'auto'});
            }
            child.setStyle({width: w+'px', height: h+'px', position: 'absolute', top: child_top+'px', left: child_left+'px'});
            child.resize(w,h);
          }
          x += child_length+(horizontal ? borders[index].width : borders[index].height);
        }
      }
      /*element.makePositioned();*/

    }
    element.setStyle({height: height+'px', width: width+'px'});
    element.removeClassName("unresized");
    element.addClassName("resized");
    return element;
  }

};

Element.addMethods(resizeElementMethods);


function dyliChange(dyli, id) {
  var dyli_hf =$(dyli);
  var dyli_tf =$(dyli+'_tf');
  
  return new Ajax.Request(dyli_hf.getAttribute('href'), {
      method: 'get',
        parameters: {id: id},
        onSuccess: function(response) {
        var obj = response.responseJSON;
        if (obj!== null) {
          dyli_hf.value = obj.hf_value;
          dyli_tf.value = obj.tf_value;
        }
      }
  });
}




var overlays = 0;

function openDialog(url) {
  var body   = document.body || document.getElementsByTagName("BODY")[0];
  var dims   = document.viewport.getDimensions();
  var height = dims.height; 
  var width  = dims.width;
  var dialog_id = 'dialog'+overlays;
  return new Ajax.Request(url, {
      method: 'get',
        parameters: {dialog: dialog_id},
        onSuccess: function(response) {
        /* Insert code creation here */
        var overlay = $('overlay');
        if (overlay === null) {
          overlay = new Element('div', {id: 'overlay', style: 'z-index:1; position:absolute; top:0; left 0; width:'+width+'px; height: '+height+'px; opacity: 0.5'});
          /*  opacity: 0.5 */
          body.appendChild(overlay);
        }
        overlays += 1;
        var w = 0.9*width;
        var h = 0.9*height;
        var dialog = new Element('div', {id: dialog_id, flex: 1, 'class': 'dialog', style: ' z-index:'+(2+overlays*1)+'; position:absolute; left:'+((width-w)/2)+'px; top:'+((height-h)/2)+'px; width:'+w+'px; height: '+h+'px; opacity: 1'});
        body.appendChild(dialog);
        dialog.update(response.responseText);
        return dialog.resize(w, h);
      },
        onFailure: function(response) {
        alert("FAILURE (Error "+response.status+"): "+response.reponseText);
      }
      /*      ,
        onLoading: function(request) {
        onLoading();
      },
        onLoaded: function(request) {
        onLoaded();
      }
      */
  });
}


function closeDialog(dialog) {
  dialog = $(dialog);
  dialog.remove();
  overlays -= 1;
  if (overlays === 0) {
    var overlay = $('overlay');
    if (overlay !== null) {
      overlay.remove();
    }
  }
  return true;
}

function resizeDialog(dialog) {
  dialog = $(dialog);
  dialog.resize(dialog.getWidth(), dialog.getHeight());
}


function refreshList(select, request, source_url) {
  return new Ajax.Request(source_url, {
      method: 'get',
        parameters: {selected: request.responseJSON.id},
        onSuccess: function(response) {
        var list = $(select);
        list.update(response.responseText);
      }
  });
}

function refreshAutoList(dyli, request) {
  return dyliChange(dyli, request.responseJSON.id);
}

