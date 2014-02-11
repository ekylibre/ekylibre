
(function ($, undefined) {
    "use strict";

    $.fn.mapsFromData = function () {
        $(this).each(function () {
            var mapElement = $(this), options = {}, map = {}, wkt = new Wkt.Wkt();
            if (mapElement.prop('mapLoaded') !== true) {
                options = mapElement.data('map');

                // Box
                if (options.box) {
                    if (options.box.height) {
                        mapElement.height(options.box.height);
                    }
                    if (options.box.width) {
                        mapElement.width(options.box.width);
                    }
                }
                mapElement.css({display: 'block'});


                map = L.map(mapElement[0], {maxZoom: 25, scrollWheelZoom: false,  zoomControl: false, attributionControl: false});
                map.addControl(L.control.zoom({position: 'topleft', zoomInText: '', zoomOutText: ''}))
                // Add an OpenStreetMap tile layer
                L.tileLayer.provider('OpenStreetMap.HOT').addTo(map);

                $.each(options.geometries, function (index, value) {
                    var layer = L.GeoJSON.geometryToLayer(value.shape).setStyle({weight: 2});
                    if (value.url) {
                        layer.on("click", function (e) {
                            window.location.assign(value.url);
                        });
                    }
                    layer.addTo(map);
                });

		// Scale
		map.addControl(new L.Control.Scale({imperial: false, maxWidth: 200}));

                // Bounding box
                if (options.view && options.view.boundingBox) {
                    map.fitBounds(L.latLngBounds(options.view.boundingBox));
                }
                mapElement.prop('mapLoaded', true);
            }
        });
    };

    $.loadMaps = function() {
        $('*[data-map]').mapsFromData();
    };

    $(document).ready($.loadMaps);

    $(document).on("page:load cocoon:after-insert cell:load", $.loadMaps);








    $(document).ready(function () {
        $('input[data-map-editor]').each(function () {
            var input = $(this), options, mapElement, map, drawnItems, editedLayer;
            input.attr('type', 'hidden');
            mapElement = $('<div class="map"></div>');
            mapElement.height("400px");
            input.after(mapElement);

	    options = input.data("map-editor");

            map = L.map(mapElement[0], {maxZoom: 25, zoomControl: false, attributionControl: false});

	    L.tileLayer.provider('OpenStreetMap.HOT').addTo(map);

            //L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
            //    attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
            //}).addTo(map);

	    if (options.others) {
		$.each(options.others, function (index, value) {
                    L.GeoJSON.geometryToLayer(value).setStyle({weight: 1, color: "#333"}).addTo(map);
		});
	    }

            if (options.edit) {
                L.GeoJSON.geometryToLayer(options.edit).setStyle({weight: 2, color: "#333"}).addTo(map);
                editedLayer = L.GeoJSON.geometryToLayer(options.edit);
		alert(options.view);
		if (options.view === undefined) {
                    map.fitBounds(editedLayer.getBounds());
		}
            } else {
                editedLayer = new L.FeatureGroup();
		if (options.view === undefined) {
                    map.fitWorld();
		    map.setZoom(6);
		}
            }
            editedLayer.addTo(map);

	    // Set view box
	    if (options.view) {
		if (options.view.center) {
		    map.setView(L.latLng(options.view.center[0], options.view.center[1]), 12);
		    if (options.view.zoom) {
			map.setZoom(options.view.zoom);
		    }
		} else if (options.view.bounds) {
		    map.fitBounds(options.view.bounds);
		}
	    }

            map.on('draw:created', function (e) {
                editedLayer.addLayer(e.layer);
                input.val(JSON.stringify(editedLayer.toGeoJSON()));
            });

            map.on('draw:edited', function(e) {
                input.val(JSON.stringify(editedLayer.toGeoJSON()));
            });

            map.addControl(new L.Control.Zoom({position: 'topleft', zoomInText: '', zoomOutText: ''}));
            map.addControl(new L.Control.FullScreen());
            map.addControl(new L.Control.Draw({edit: {featureGroup: editedLayer, edit: {color: "#A40"}}, draw: {marker: false, polyline: false, rectangle: false, circle: false, polygon: {allowIntersection: false, showArea: true}}}));
            map.addControl(new L.Control.Scale({imperial: false, maxWidth: 200}));
        });
    });





})( jQuery );
