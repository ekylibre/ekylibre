// Box container to handle one container with lm_left, lm_right, lm_top, lm_bottom, and lm_center
Box = Class.create({
	
    });


HBox = Class.create(Box, {
	
    });

VBox = Class.create(Box, {
	
    });





BoxContainer = Class.create({
	initialize: function(root) {
	    this.parent = $(root.parentNode); 
	    root.setStyle("padding:0; margin:0; border:0"); 
	    // Pre-compute paddings
	    $w("top left right bottom").each(function(key) { 
		    this.parent[key] = this.padding(this.parent, key);
		}.bind(this));
	    
	    // Init arrays
	    $w("lm_top lm_left lm_right lm_bottom lm_center").each(function(key) {
		    this[key] = [];
		}.bind(this));
    
	    root.childElements().each(function(element) {
		    element.style.position = "absolute";
		    element.paddingWidth   = this.fullPadding(element, "left") + this.fullPadding(element, "right");
		    element.paddingHeight  = this.fullPadding(element, "top") + this.fullPadding(element, "bottom");
		    element.marginWidth    = this.margin(element, "left") + this.margin(element, "right");
		    element.marginHeight   = this.margin(element, "top") + this.margin(element, "bottom");
      
		    if (element.hasClassName("lm_top")) {
			this.lm_top.push(element);
		    } else if (element.hasClassName("lm_left")) {
			this.lm_left.push(element);  
		    } else if (element.hasClassName("lm_right")) {
			this.lm_right.unshift(element);
		    } else if (element.hasClassName("lm_bottom")) {
			this.lm_bottom.unshift(element);  
		    } else if (element.hasClassName("lm_center")) {
			if (this.lm_center.length > 0) {
			    throw("Only one lm_center per lm_container");
			}
			this.lm_center.push(element);
		    }
		}.bind(this));
	},
  
	updateSize: function() {      
	    var d = this.parent.getDimensions();
	    var w = d.width - this.parent.left - this.parent.right;
	    var h = d.height - this.parent.top - this.parent.bottom;   
	    var that = this; // To avoid too many binds
   
	    // Set position and size of all top elements  
	    var top = this.parent.top;     
	    this.lm_top.each(function(element) {   
		    var s = element.style;   
		    that.setPositivePxValue(s, 'width', w - element.paddingWidth);
		    s.top = top + "px";
		    top += element.getHeight() + element.marginHeight;
		});
	    h -= top - this.parent.top;
    
	    // Set position and size of all bottom elements
	    var bottom = this.parent.bottom;
	    this.lm_bottom.each(function(element) { 
		    var s = element.style;   
		    that.setPositivePxValue(s, 'width', w - element.paddingWidth);
		    s.bottom = bottom + "px";
		    bottom += element.getHeight() + element.marginHeight;
		});
	    h -= bottom - this.parent.bottom;
     
	    // Set position and size of all left elements
	    var left = this.parent.left;          
	    this.lm_left.each(function(element) {
		    var s = element.style;  
		    that.setPositivePxValue(s, 'height', h - element.paddingHeight);
		    s.top  = top + "px";  
		    s.left = left + "px";  
		    left += element.getWidth() + element.marginWidth;
		});
	    w -= left;
    
	    // Set position and size of all right elements
	    var right = this.parent.right;
	    this.lm_right.each(function(element) {
		    var s = element.style;
		    that.setPositivePxValue(s, 'height', h - element.paddingHeight);
		    s.top   = top + "px";  
		    s.right = right + "px";  
		    right += element.getWidth() + element.marginWidth;
		});
	    w -= right;
     
	    // Set position and size of all center elements
	    // Only one center for this version
	    var center = this.lm_center.first();
	    var s = center.style;
	    s.top  = top + "px"; 
	    s.left = left + "px";  
	    this.setPositivePxValue(s, 'width', w - center.paddingWidth);
	    this.setPositivePxValue(s, 'height', h - center.paddingHeight);
	},
     
	// Private functions
	fullPadding: function(element, s) {   
	    return this.padding(element, s) + this.border(element, s) + this.margin(element, s);
	},

	border: function(element, s) {   
	    var border = parseInt(element.getStyle("border-" + s + "-width") || 0, 10);
	    if (isNaN(border)) {   // Test for IE!!
		border = 0;
	    }
	    return border;
	},

	padding: function(element, s) {   
	    var padding = parseInt(element.getStyle("padding-" + s) || 0, 10);
	    if (isNaN(padding)) {  // Test for IE!!
		padding = 0;
	    }
	    return padding;
	},

	margin: function(element, s) {   
	    var margin = parseInt(element.getStyle("margin-" + s) || 0, 10);
	    if (isNaN(margin)) {  // Test for IE!!
		margin = 0;
	    }
	    return margin;
	},
  
	setPositivePxValue:function(objet, key, value) {
	    objet[key] =  (value > 0 ? value : 0) + "px";
	}
    });
                 
// Box manager: handles N box container
BoxManager = Class.create({
	initialize: function(root) {
	    this.root = root || document.body || document.getElementsByTagName('body')[0];
	    if (this.root === undefined) {
		alert('Root is undefined '+document+" "+this.root);
		return;
	    }
	    this.init();
	    Event.observe(window, "resize", this.resize.bind(this));
	},
  
	reset: function() {
	    this.init.bind(this).defer();
	}, 
  
	add: function(root) {       
	    this.addElement.bind(this, root, true).defer();
	},
  
	// Private functions
	init: function() {
	    this.containers = []; 
	    this.addElement(this.root);  
	    this.resize();    
	},
  
	resize: function() {
	    $('body').setStyle("height:"+document.viewport.getDimensions().height+"px");
	    this.containers.invoke("updateSize"); 
	    window.setTimeout(function() {this.containers.invoke("updateSize")}.bind(this), 300);
	},
  
	addElement: function(element, doResize) {
	    $(element).select(".lm_container").each(function(element) {
		    this.containers.push(new BoxContainer(element));
		}.bind(this));
	    if (doResize) {
		this.resize();
	    }
	}
    });

var boxManager = null;
Event.observe(window, "load", function() { boxManager = new BoxManager(); });
/*document.observe("dom:loaded", function() { boxManager = new BoxManager(); } );*/
