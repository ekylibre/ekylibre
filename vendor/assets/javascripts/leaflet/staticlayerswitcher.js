/*
 * Layer switcher control that isn't a popup button.
 * Does not support overlay layers.
 */
L.StaticLayerSwitcher = L.Control.extend({
	includes: L.Mixin.Events,

	options: {
		position: 'topright',
		editable: false,
		bgColor: 'white',
		selectedColor: '#ddd',
		enforceOSM: false,
		maxLayers: 7
	},

	initialize: function( layers, options ) {
		L.setOptions(this, options);
		this._layers = [];
		this._selected = 0;
		this._layerList = window.layerList && 'isOpenStreetMapLayer' in window.layerList;
		if( layers ) {
			if( 'push' in layers && 'splice' in layers ) { // in IE arrays can be [object Object]
				for( var i = 0; i < layers.length; i++ )
					this.addLayer(layers[i]);
			} else {
				for( var id in layers )
					this.addLayer(id, layers[id]);
			}
		}
	},

	getLayers: function() {
		var result = [];
		for( var i = 0; i < this._layers.length; i++ )
			result.push(this._layers[i].layer);
		return result;
	},

	getLayerIds: function() {
		var result = [];
		for( var i = 0; i < this._layers.length; i++ )
			result.push(this._layers[i].id);
		return result;
	},

	getSelectedLayer: function() {
		return this._layers.length > 0 && this._selected < this._layers.length ? this._layers[this._selected].layer : null;
	},

	getSelectedLayerId: function() {
		return this._layers.length > 0 && this._selected < this._layers.length ? this._layers[this._selected].id : '';
	},

	updateId: function( layer, id ) {
		var i = this._findLayer(layer),
			l = i >= 0 && this._layers[i];
		if( l && l.id !== id ) {
			l.id = id;
			if( l.fromList ) {
				var onMap = this._map && this._map.hasLayer(layer),
					newLayer = this._layerList ? window.layerList.getLeafletLayer(id) : null;
				if( onMap )
					this._map.removeLayer(layer);
				if( newLayer ) {
					l.layer = newLayer;
					if( onMap )
						this._map.addLayer(newLayer);
				} else {
					this._layers.splice(i, 1);
				}
			}
			this._update();
			return layer;
		}
		return null;
	},

	addLayer: function( id, layer ) {
		if( this._layers.length >= this.options.maxLayers )
			return;
		var l = layer || (this._layerList && window.layerList.getLeafletLayer(id));
		if( l ) {
			this._layers.push({ id: id, layer: l, fromList: !layer });
			var osmidx = this._findFirstOSMLayer();
			if( osmidx > 0 ) {
				var tmp = this._layers[osmidx];
				this._layers[osmidx] = this._layers[0];
				this._layers[0] = tmp;
			}
			if( this._map )
				this._addMandatoryOSMLayer();
			this._update();
			this.fire('layerschanged', { layers: this.getLayerIds() });
			if( this._layers.length == 1 )
				this.fire('selectionchanged', { selected: this.getSelectedLayer(), selectedId: this.getSelectedLayerId() });
			return layer;
		}
		return null;
	},

	removeLayer: function( layer ) {
		var i = this._findLayer(layer);
		if( i >= 0 ) {
			var removingSelected = this._selected == i;
			if( removingSelected )
				this._map.removeLayer(layer);
			this._layers.splice(i, 1);
			if( i === 0 ) {
				// if first layer is not OSM layer, swap it with first OSM layer
				var osmidx = this._findFirstOSMLayer();
				if( osmidx > 0 ) {
					var tmp = this._layers[osmidx];
					this._layers[osmidx] = this._layers[0];
					this._layers[0] = tmp;
				}
			}
			if( this._selected >= this._layers.length && this._selected > 0 )
				this._selected = this._layers.length - 1;
			this._addMandatoryOSMLayer();
			this._update();
			this.fire('layerschanged', { layers: this.getLayerIds() });
			if( removingSelected )
				this.fire('selectionchanged', { selected: this.getSelectedLayer(), selectedId: this.getSelectedLayerId() });
			return layer;
		}
		return null;
	},

	moveLayer: function( layer, moveDown ) {
		var pos = this._findLayer(layer),
			newPos = moveDown ? pos + 1 : pos - 1;
		if( pos >= 0 && newPos >= 0 && newPos < this._layers.length ) {
			if( this.options.enforceOSM && pos + newPos == 1 && this._layerList &&
					!window.layerList.isOpenStreetMapLayer(this._layers[1].layer) ) {
				var nextOSM = this._findFirstOSMLayer(1);
				if( pos === 0 && nextOSM > 1 )
					newPos = nextOSM;
				else
					return;
			}
			var tmp = this._layers[pos];
			this._layers[pos] = this._layers[newPos];
			this._layers[newPos] = tmp;
			if( pos == this._selected )
				this._selected = newPos;
			else if( newPos == this._selected )
				this._selected = pos;
			this._update();
			this.fire('layerschanged', { layers: this.getLayerIds() });
		}
	},

	_findFirstOSMLayer: function( start ) {
		if( !this._layerList || !this.options.enforceOSM )
			return start || 0;
		var i = start || 0;
		while( i < this._layers.length && !window.layerList.isOpenStreetMapLayer(this._layers[i].layer) )
			i++;
		if( i >= this._layers.length )
			i = -1;
		return i;
	},

	_addMandatoryOSMLayer: function() {
		if( this.options.enforceOSM && this._layers.length > 0 && this._findFirstOSMLayer() < 0 ) {
			var layer = L.tileLayer('http://tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution: 'Map &copy; <a href=\"http://openstreetmap.org\">OpenStreetMap</a>', minZoom: 0, maxZoom: 19 });
			if( this._selected < this._layers.length )
				this._selected++;
			this._layers.unshift({ id: 'OpenStreetMap', layer: layer, fromList: false });
		}
	},

	_findLayer: function( layer ) {
		for( var i = 0; i < this._layers.length; i++ )
			if( this._layers[i].layer === layer )
				return i;
		return -1;
	},

	onAdd: function( map ) {
		var container = L.DomUtil.create('div', 'leaflet-bar');
		if (!L.Browser.touch) {
			L.DomEvent.disableClickPropagation(container);
			L.DomEvent.on(container, 'mousewheel', L.DomEvent.stopPropagation);
		} else {
			L.DomEvent.on(container, 'click', L.DomEvent.stopPropagation);
		}
		this._map = map;
		this._container = container;
		this._addMandatoryOSMLayer();
		this._update();
		return container;
	},

	// accepts value at index in this._layers array
	_createItem: function( layerMeta ) {
		var div = document.createElement('div');
		div.style.backgroundColor = this.options.bgColor;
		this._addHoverStyle(div, 'backgroundColor', this.options.selectedColor);
		div.style.padding = '4px 10px';
		div.style.margin = '0';
		div.style.color = 'black';
		div.style.cursor = 'default';
		var label = !layerMeta.fromList ? layerMeta.id : (this._layerList ? window.layerList.getLayerName(layerMeta.id) : 'Layer');
		div.appendChild(document.createTextNode(label));
		if( this.options.editable )
			div.appendChild(this._createLayerControls(layerMeta.layer));
		L.DomEvent.on(div, 'click', function() {
			var index = this._findLayer(layerMeta.layer);
			if( this._selected != index ) {
				this._selected = index;
				this._update();
				this.fire('selectionchanged', { selected: this.getSelectedLayer(), selectedId: this.getSelectedLayerId() });
			}
		}, this);
		return div;
	},

	_createLayerControls: function( layer ) {
		var upClick = document.createElement('span');
		upClick.innerHTML ='&#x25B4;'; // &utrif;
		upClick.style.cursor = 'pointer';
		this._addHoverStyle(upClick, 'color', '#aaa');
		L.DomEvent.on(upClick, 'click', function() {
			this.moveLayer(layer, false);
		}, this);

		var downClick = document.createElement('span');
		downClick.innerHTML ='&#x25BE;'; // &dtrif;
		downClick.style.cursor = 'pointer';
		downClick.style.marginLeft = '6px';
		this._addHoverStyle(downClick, 'color', '#aaa');
		L.DomEvent.on(downClick, 'click', function() {
			this.moveLayer(layer, true);
		}, this);

		var xClick = document.createElement('span');
		xClick.innerHTML ='&#x2A2F;'; // &Cross;
		xClick.style.cursor = 'pointer';
		xClick.style.marginLeft = '6px';
		this._addHoverStyle(xClick, 'color', '#aaa');
		L.DomEvent.on(xClick, 'click', function() {
			this.removeLayer(layer);
		}, this);

		var span = document.createElement('span');
		span.style.fontSize = '12pt';
		span.style.marginLeft = '12px';
		span.appendChild(upClick);
		span.appendChild(downClick);
		span.appendChild(xClick);
		L.DomEvent.on(span, 'click', L.DomEvent.stopPropagation);
		return span;
	},

	_addHoverStyle: function( element, name, value ) {
		var defaultValue = element.style[name];
		L.DomEvent.on(element, 'mouseover', function() {
			if( element.style[name] !== value ) {
				defaultValue = element.style[name];
				element.style[name] = value;
			}
		});
		element.resetHoverStyle = function() {
			element.style[name] = defaultValue;
		};
		element.updateHoverDefault = function() {
			defaultValue = element.style[name];
		};
		L.DomEvent.on(element, 'mouseout', element.resetHoverStyle);
	},

	_recursiveCall: function( element, functionName ) {
		if( element && element[functionName] ) {
			element[functionName].call(element);
			var children = element.getElementsByTagName('*');
			for( var j = 0; j < children.length; j++ )
				if( children[j][functionName] )
					children[j][functionName].call(children[j]);
		}
	},

	_update: function() {
		if( !this._container )
			return;
		var presentDivs = [];
		for( var i = 0; i < this._layers.length; i++ ) {
			var l = this._layers[i];
			if( !l.div )
				l.div = this._createItem(l);
			else
				this._recursiveCall(l.div, 'resetHoverStyle');
			l.div.style.background = this._selected == i ? this.options.selectedColor : this.options.bgColor;
			l.div.style.borderTop = i ? '1px solid ' + this.options.selectedColor : '0';
			this._recursiveCall(l.div, 'updateHoverDefault');
			this._container.appendChild(l.div);
			presentDivs.push(l.div);
			if( this._map.hasLayer(l.layer) && this._selected != i )
				this._map.removeLayer(l.layer);
			else if( !this._map.hasLayer(l.layer) && this._selected == i )
				this._map.addLayer(l.layer);
		}
		
		var alldivs = this._container.childNodes, found;
		for( var j = 0; j < alldivs.length; j++ ) {
			found = false;
			for( var k = 0; k < presentDivs.length; k++ )
				if( presentDivs[k] === alldivs[j] )
					found = true;
			if( !found )
				this._container.removeChild(alldivs[j]);
		}
	}
});

L.staticLayerSwitcher = function( layers, options ) {
	return new L.StaticLayerSwitcher(layers, options);
};
