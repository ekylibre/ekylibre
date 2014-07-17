/**
 * @author Hugo
 */
/*
Style options based on:
- path: http://leafletjs.com/reference.html#path-options
- icon: http://leafletjs.com/reference.html#icon

Markers from:
- Maki Markers from mapbox: https://www.mapbox.com/maki/
*/

L.StyleForms = L.Class.extend({
    options: {
        currentMarkerStyle: {
            size: 'm',
            color: '48a'
        }
    },

    initialize: function(options) {
        L.setOptions(this, options);
    },

    clearForm: function() {
        this.options.styleEditorUi.innerHTML = '';
    },

    createGeometryForm: function() {
        this.clearForm();

        this.createColor();
        this.createOpacity();
        this.createStroke();

        //Polygons, Circles get the fill options
        if (this.options.currentElement.target instanceof L.Polygon){

            this.createFillColor();
            this.createFillOpacity();
        }

    },



    createMarkerForm: function() {
        this.clearForm();

        this.createIconUrl();
        this.createMarkerColor();
        this.createMarkerSize();
    },

    setNewMarker: function() {
        var markerStyle = this.options.currentMarkerStyle;

        if (markerStyle.size && markerStyle.icon && markerStyle.color) {
            var iconSize;
            switch (markerStyle.size) {
                case 's':
                    iconSize = [20, 50];
                    break;
                case 'm':
                    iconSize = [30, 70];
                    break;
                case 'l':
                    iconSize = [35, 90];
                    break;

            }

            var newIcon = new L.Icon({
                iconUrl: this.options.markerApi + 'pin-' + markerStyle.size + '-' + markerStyle.icon + '+' + markerStyle.color + '.png',
                iconSize: iconSize
            });
            var currentElement = this.options.currentElement.target;
            currentElement.setIcon(newIcon);
            this.fireChangeEvent(currentElement);
        }
    },

    createIconUrl: function() {
        var label = L.DomUtil.create('label', 'leaflet-styleeditor-label', this.options.styleEditorUi);
        label.innerHTML = 'Icon:';

        this.createSelectInput(this.options.styleEditorUi, function(e) {
            var value = e.target.value;
            this.options.currentMarkerStyle.icon = value;
            this.setNewMarker();
        }.bind(this), this.options.markers);

    },

    createMarkerColor: function() {
        var label = L.DomUtil.create('label', 'leaflet-styleeditor-label', this.options.styleEditorUi);
        label.innerHTML = 'Color:';

        this.createColorPicker(this.options.styleEditorUi, function(e) {
            var color = this.rgbToHex(e.target.style.backgroundColor);
            this.options.currentMarkerStyle.color = color.replace("#", "");
            this.setNewMarker();
        }.bind(this));

    },

    createMarkerSize: function() {

        var label = L.DomUtil.create('label', 'leaflet-styleeditor-label', this.options.styleEditorUi);
        label.innerHTML = 'Size:';

        var s = L.DomUtil.create('div', 'leaflet-styleeditor-sizeicon sizeicon-small', this.options.styleEditorUi);
        var m = L.DomUtil.create('div', 'leaflet-styleeditor-sizeicon sizeicon-medium', this.options.styleEditorUi);
        var l = L.DomUtil.create('div', 'leaflet-styleeditor-sizeicon sizeicon-large', this.options.styleEditorUi);

        L.DomEvent.addListener(s, 'click', function() {
            this.options.currentMarkerStyle.size = 's';
            this.setNewMarker();
        }, this);

        L.DomEvent.addListener(m, 'click', function() {
            this.options.currentMarkerStyle.size = 'm';
            this.setNewMarker();
        }, this);

        L.DomEvent.addListener(l, 'click', function() {
            this.options.currentMarkerStyle.size = 'l';
            this.setNewMarker();
        }, this);

    },

    createColor: function() {
        var label = L.DomUtil.create('label', 'leaflet-styleeditor-label', this.options.styleEditorUi);
        label.innerHTML = 'Color:';

        this.createColorPicker(this.options.styleEditorUi, function(e) {
            var color = this.rgbToHex(e.target.style.backgroundColor);
            this.setStyle('color', color);
        }.bind(this));
    },

    createStroke: function() {
        var label = L.DomUtil.create('label', 'leaflet-styleeditor-label', this.options.styleEditorUi);
        label.innerHTML = 'Line Stroke:';

        var stroke1 = L.DomUtil.create('div', 'leaflet-styleeditor-stroke', this.options.styleEditorUi);
        stroke1.style.backgroundPosition = "0px -75px";

        var stroke2 = L.DomUtil.create('div', 'leaflet-styleeditor-stroke', this.options.styleEditorUi);
        stroke2.style.backgroundPosition = "0px -95px";

        var stroke3 = L.DomUtil.create('div', 'leaflet-styleeditor-stroke', this.options.styleEditorUi);
        stroke3.style.backgroundPosition = "0px -115px";

        L.DomUtil.create('br', 'bla', this.options.styleEditorUi);

        L.DomEvent.addListener(stroke1, 'click', function(e) {
            this.setStyle('dashArray', '1');
        }, this);
        L.DomEvent.addListener(stroke2, 'click', function(e) {
            this.setStyle('dashArray', '10,10');
        }, this);
        L.DomEvent.addListener(stroke3, 'click', function(e) {
            this.setStyle('dashArray', '15, 10, 1, 10');
        }, this);
    },



    createOpacity: function() {
        var label = L.DomUtil.create('label', 'leaflet-styleeditor-label', this.options.styleEditorUi);
        label.innerHTML = 'Opacity:';

        this.createNumberInput(this.options.styleEditorUi, function(e) {
            var value = e.target.value;
            this.setStyle('opacity', value);
        }.bind(this), this.options.currentElement.target.options.opacity, 0, 1, 0.1);
    },

    createFillColor: function() {
        var label = L.DomUtil.create('label', 'leaflet-styleeditor-label', this.options.styleEditorUi);
        label.innerHTML = 'Fill Color:';

        this.createColorPicker(this.options.styleEditorUi, function(e) {
            var color = this.rgbToHex(e.target.style.backgroundColor);
            this.setStyle('fillColor', color);
        }.bind(this));
    },

    createFillOpacity: function() {
        var label = L.DomUtil.create('label', 'leaflet-styleeditor-label', this.options.styleEditorUi);
        label.innerHTML = 'Fill Opacity:';

        this.createNumberInput(this.options.styleEditorUi, function(e) {
            var value = e.target.value;
            this.setStyle('fillOpacity', value);
        }.bind(this), this.options.currentElement.target.options.fillOpacity, 0, 1, 0.1);

    },

    createColorPicker: function(parentDiv, callback) {
        var colorPickerDiv = L.DomUtil.create('div', 'leaflet-styleeditor-colorpicker', parentDiv);
        this.options.colorRamp.forEach(function(color) {
            var elem = L.DomUtil.create('div', 'leaflet-styleeditor-color', colorPickerDiv);
            elem.style.backgroundColor = color;

            L.DomEvent.addListener(elem, "click", callback, this);
        }, this);

        L.DomUtil.create('br', '', parentDiv);
        L.DomUtil.create('br', '', parentDiv);

        return colorPickerDiv;
    },

    createNumberInput: function(parentDiv, callback, value, min, max, step) {
        var numberInput = L.DomUtil.create('input', 'leaflet-styleeditor-input', parentDiv);
        numberInput.setAttribute('type', 'number');
        numberInput.setAttribute('value', value);
        numberInput.setAttribute('min', min);
        numberInput.setAttribute('max', max);
        numberInput.setAttribute('step', step);

        L.DomEvent.addListener(numberInput, 'change', callback, this);
        L.DomEvent.addListener(numberInput, 'keyup', callback, this);

        L.DomUtil.create('br', '', parentDiv);
        L.DomUtil.create('br', '', parentDiv);

        return numberInput;
    },

    createSelectInput: function(parentDiv, callback, options) {
        var selectBox = L.DomUtil.create('select', 'leaflet-styleeditor-select', parentDiv);

        options.forEach(function(option) {
            var selectOption = L.DomUtil.create('option', 'leaflet-styleeditor-option', selectBox);
            selectOption.setAttribute('value', option);
            selectOption.innerHTML = option;
        }, this);

        L.DomEvent.addListener(selectBox, 'change', callback, this);

        return selectBox;
    },

    setStyle: function(option, value) {
        var newStyle = {};
        newStyle[option] = value;
        var currentElement = this.options.currentElement.target;
        currentElement.setStyle(newStyle);
        this.fireChangeEvent(currentElement);
    },

    fireChangeEvent: function(element){
        this.options.currentElement.target._map.fireEvent('styleeditor:changed', element);
    },

    componentToHex: function(c) {
        var hex = c.toString(16);
        return hex.length === 1 ? "0" + hex : hex;
    },

    rgbToHex: function(rgb) {
        rgb = rgb.substring(4).replace(")", "").split(",");
        return "#" + this.componentToHex(parseInt(rgb[0], 10)) + this.componentToHex(parseInt(rgb[1], 10)) + this.componentToHex(parseInt(rgb[2], 10));
    },



});