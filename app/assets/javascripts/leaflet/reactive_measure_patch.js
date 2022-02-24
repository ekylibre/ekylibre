L.Draw.Polyline.include({
    __updatePosition: function (latlng, options) {
        var container, container_width, labelWidth, map_width, pos, styles;
        if (options == null) {
            options = {};
        }
        pos = this._map.latLngToLayerPoint(latlng);
        if (this._container) {
            labelWidth = this._container.offsetWidth;
            map_width = this._map._container.offsetWidth;
            L.DomUtil.removeClass(this._container, 'leaflet-draw-tooltip-left');
            this._container.style.visibility = 'inherit';
            container = this._map.layerPointToContainerPoint(pos);
            styles = window.getComputedStyle(this._container);
            container_width =
                this._container.offsetWidth +
                parseInt(styles.paddingLeft) +
                parseInt(styles.paddingRight) +
                parseInt(styles.marginLeft) +
                parseInt(styles.marginRight);
            if (container.x < 0 || container.x > map_width - container_width || container.y < this._container.offsetHeight) {
                pos = pos.add(L.point(-container_width, 0));
                L.DomUtil.addClass(this._container, 'leaflet-draw-tooltip-left');
            }
            return L.DomUtil.setPosition(this._container, pos);
        }
    },
});
