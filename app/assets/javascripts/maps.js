
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
                L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
                    attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
                }).addTo(map);
                $.each(options.geometries, function (index, value) {
                    var layer = L.geoJson(value.shape);
                    if (value.url) {
                        layer.on("click", function (e) {
                            window.location.assign(value.url);
                        });
                    }
                    layer.addTo(map);
                });

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
        $('input[type="spatial"]').each(function () {
            var input = $(this), mapElement, map, drawnItems, editedLayer;
            input.attr('type', 'hidden');
            mapElement = $('<div class="map"></div>');
            mapElement.height("400px");
            input.after(mapElement);

            map = L.map(mapElement[0], {maxZoom: 25, zoomControl: false, attributionControl: false});

            L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
                attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
            }).addTo(map);

            if (input.data('spatial')) {
                L.GeoJSON.geometryToLayer(input.data('spatial')).addTo(map);
                editedLayer = L.GeoJSON.geometryToLayer(input.data('spatial'));
                map.fitBounds(editedLayer.getBounds());
            } else {
                editedLayer = new L.FeatureGroup();
                map.fitWorld();
            }
            editedLayer.addTo(map);

            map.on('draw:created', function (e) {
                editedLayer.addLayer(e.layer);
                input.val(JSON.stringify(editedLayer.toGeoJSON()));
            });

            map.on('draw:edited', function(e) {
                input.val(JSON.stringify(editedLayer.toGeoJSON()));
            });

            map.addControl(new L.Control.Zoom({position: 'topleft', zoomInText: '', zoomOutText: ''}));
            map.addControl(new L.Control.FullScreen());
            map.addControl(new L.Control.Draw({edit: {featureGroup: editedLayer}, draw: {marker: false, polyline: false, rectangle: false, circle: false}}));
            map.addControl(new L.Control.Scale({imperial: false, maxWidth: 200}));
        });
    });





})( jQuery );
