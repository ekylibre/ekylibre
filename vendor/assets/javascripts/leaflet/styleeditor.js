/**
 * @author Hugo
 */
L.Control.StyleEditor = L.Control.extend({

    options: {
        position: 'topleft',
        enabled: false,
        colorRamp: ['#1abc9c', '#2ecc71', '#3498db', '#9b59b6', '#34495e', '#16a085', '#27ae60', '#2980b9', '#8e44ad', '#2c3e50', '#f1c40f', '#e67e22', '#e74c3c', '#ecf0f1', '#95a5a6', '#f39c12', '#d35400', '#c0392b', '#bdc3c7', '#7f8c8d'],
        markerApi: 'http://api.tiles.mapbox.com/v3/marker/',
        markers: ['circle-stroked', 'circle', 'square-stroked', 'square', 'triangle-stroked', 'triangle', 'star-stroked', 'star', 'cross', 'marker-stroked', 'marker', 'religious-jewish', 'religious-christian', 'religious-muslim', 'cemetery', 'rocket', 'airport', 'heliport', 'rail', 'rail-metro', 'rail-light', 'bus', 'fuel', 'parking', 'parking-garage', 'airfield', 'roadblock', 'ferry', 'harbor', 'bicycle', 'park', 'park2', 'museum', 'lodging', 'monument', 'zoo', 'garden', 'campsite', 'theatre', 'art-gallery', 'pitch', 'soccer', 'america-football', 'tennis', 'basketball', 'baseball', 'golf', 'swimming', 'cricket', 'skiing', 'school', 'college', 'library', 'post', 'fire-station', 'town-hall', 'police', 'prison', 'embassy', 'beer', 'restaurant', 'cafe', 'shop', 'fast-food', 'bar', 'bank', 'grocery', 'cinema', 'pharmacy', 'hospital', 'danger', 'industrial', 'warehouse', 'commercial', 'building', 'place-of-worship', 'alcohol-shop', 'logging', 'oil-well', 'slaughterhouse', 'dam', 'water', 'wetland', 'disability', 'telephone', 'emergency-telephone', 'toilets', 'waste-basket', 'music', 'land-use', 'city', 'town', 'village', 'farm', 'bakery', 'dog-park', 'lighthouse', 'clothing-store', 'polling-place', 'playground', 'entrance', 'heart', 'london-underground', 'minefield', 'rail-underground', 'rail-above', 'camera', 'laundry', 'car', 'suitcase', 'hairdresser', 'chemist', 'mobilephone', 'scooter'],
        editlayers: [],
        openOnLeafletDraw: true,
        showTooltip: true
    },

    onAdd: function(map) {
        this.options.map = map;
        return this.createUi();
    },

    createUi: function() {
        var controlDiv = this.options.controlDiv = L.DomUtil.create('div', 'leaflet-control-styleeditor');
        var controlUI = this.options.controlUI = L.DomUtil.create('div', 'leaflet-control-styleeditor-interior', controlDiv);
        controlUI.title = 'Style Editor';

        var styleEditorDiv = this.options.styleEditorDiv = L.DomUtil.create('div', 'leaflet-styleeditor', this.options.map._container);
        this.options.styleEditorHeader = L.DomUtil.create('div', 'leaflet-styleeditor-header', styleEditorDiv);

        this.options.styleEditorUi = L.DomUtil.create('div', 'leaflet-styleeditor-interior', styleEditorDiv);

        this.addDomEvents();
        this.addLeafletDrawEvents();
        this.addButtons();

        return controlDiv;
    },

    addDomEvents: function() {
        L.DomEvent.addListener(this.options.controlDiv, 'click', this.clickHandler, this);
        L.DomEvent.addListener(this.options.styleEditorDiv, 'mouseenter', this.disableLeafletActions, this);
        L.DomEvent.addListener(this.options.styleEditorDiv, 'mouseleave', this.enableLeafletActions, this);
    },

    addLeafletDrawEvents: function() {
        if (L.Control.Draw) {
            if (this.options.openOnLeafletDraw) {
                this.options.map.on('draw:created', function(layer) {
                    this.initChangeStyle({
                        "target": layer.layer
                    });
                }, this);
            }
        }
    },

    addButtons: function() {
        var closeBtn = L.DomUtil.create('button', 'leaflet-styleeditor-button styleeditor-closeBtn', this.options.styleEditorHeader);
        var sizeToggleBtn = this.options.sizeToggleBtn = L.DomUtil.create('button', 'leaflet-styleeditor-button styleeditor-inBtn', this.options.styleEditorHeader);

        L.DomEvent.addListener(closeBtn, 'click', this.hideEditor, this);
        L.DomEvent.addListener(sizeToggleBtn, 'click', this.toggleEditorSize, this);
    },


    clickHandler: function(e) {
        this.options.enabled = !this.options.enabled;

        if (this.options.enabled) {
            this.enable();
        } else {
            L.DomUtil.removeClass(this.options.controlUI, 'enabled');
            this.disable();
        }
    },

    disableLeafletActions: function() {
        this.options.map.dragging.disable();
        this.options.map.touchZoom.disable();
        this.options.map.doubleClickZoom.disable();
        this.options.map.scrollWheelZoom.disable();
        this.options.map.boxZoom.disable();
        this.options.map.keyboard.disable();
    },

    enableLeafletActions: function() {
        this.options.map.dragging.enable();
        this.options.map.touchZoom.enable();
        this.options.map.doubleClickZoom.enable();
        this.options.map.scrollWheelZoom.enable();
        this.options.map.boxZoom.enable();
        this.options.map.keyboard.enable();
    },

    enable: function() {
        L.DomUtil.addClass(this.options.controlUI, "enabled");
        this.options.map.eachLayer(this.addEditClickEvents, this);

        this.createMouseTooltip();
    },

    disable: function() {
        this.options.editlayers.forEach(this.removeEditClickEvents, this);
        this.options.editlayers = [];
        this.hideEditor();

        this.removeMouseTooltip();
    },

    addEditClickEvents: function(layer) {
        if (layer._latlng || layer._latlngs) {
            var evt = layer.on('click', this.initChangeStyle, this);
            this.options.editlayers.push(evt);
        }
    },

    removeEditClickEvents: function(layer) {
        layer.off('click', this.initChangeStyle, this);
    },

    hideEditor: function() {
        L.DomUtil.removeClass(this.options.styleEditorDiv, 'editor-enabled');
    },

    toggleEditorSize: function() {
        if (L.DomUtil.hasClass(this.options.styleEditorDiv, 'leaflet-styleeditor-full')) {
            L.DomUtil.removeClass(this.options.styleEditorDiv, 'leaflet-styleeditor-full');
            L.DomUtil.removeClass(this.options.styleEditorUi, 'leaflet-styleeditor-full');
            L.DomUtil.removeClass(this.options.sizeToggleBtn, 'styleeditor-outBtn');
            L.DomUtil.addClass(this.options.sizeToggleBtn, 'styleeditor-inBtn');

        } else {
            L.DomUtil.addClass(this.options.styleEditorDiv, 'leaflet-styleeditor-full');
            L.DomUtil.addClass(this.options.styleEditorUi, 'leaflet-styleeditor-full');
            L.DomUtil.removeClass(this.options.sizeToggleBtn, 'styleeditor-inBtn');
            L.DomUtil.addClass(this.options.sizeToggleBtn, 'styleeditor-outBtn');
        }
    },

    showEditor: function() {
        var editorDiv = this.options.styleEditorDiv;
        if (!L.DomUtil.hasClass(editorDiv, 'editor-enabled')) {
            L.DomUtil.addClass(editorDiv, 'editor-enabled');
        }
    },

    initChangeStyle: function(e) {
        this.options.currentElement = e;

        this.showEditor();
        this.removeMouseTooltip();

        var layer = e.target;

        if (layer instanceof L.Marker) {
            //marker
            this.createMarkerForm(layer);
        } else {
            //geometry with normal styles
            this.createGeometryForm(layer);
        }

    },

    createGeometryForm: function(layer) {
        var styleForms = new L.StyleForms({
            colorRamp: this.options.colorRamp,
            styleEditorUi: this.options.styleEditorUi,
            currentElement: this.options.currentElement
        });

        styleForms.createGeometryForm();
    },

    createMarkerForm: function(layer) {
        var styleForms = new L.StyleForms({
            colorRamp: this.options.colorRamp,
            styleEditorUi: this.options.styleEditorUi,
            currentElement: this.options.currentElement,
            markerApi: this.options.markerApi,
            markers: this.options.markers
        });

        styleForms.createMarkerForm();
    },

    createMouseTooltip: function() {
        if (this.options.showTooltip) {
            var mouseTooltip = this.options.mouseTooltip = L.DomUtil.create('div', 'leaflet-styleeditor-mouseTooltip', document.body);
            mouseTooltip.innerHTML = 'Click on the element you want to style';

            L.DomEvent.addListener(window, 'mousemove', this.moveMouseTooltip, this);
        }

    },

    removeMouseTooltip: function() {
        L.DomEvent.removeListener(window, 'mousemove', this.moveMouseTooltip);

        if (this.options.mouseTooltip && this.options.mouseTooltip.parentNode) {
            this.options.mouseTooltip.parentNode.removeChild(this.options.mouseTooltip);
        }
    },

    moveMouseTooltip: function(e) {
        var x = e.clientX,
            y = e.clientY;
        this.options.mouseTooltip.style.top = (y + 15) + 'px';
        this.options.mouseTooltip.style.left = (x) + 'px';
    }


});

L.control.styleEditor = function(options) {
    return new L.Control.StyleEditor(options);
};