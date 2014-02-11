
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


                map = L.map(mapElement[0], {maxZoom: 23, zoomControl: false}); // .setView(, 18);
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


})( jQuery );
