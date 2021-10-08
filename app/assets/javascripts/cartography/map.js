(function (E, $) {
    if (!E.Events) {
        E.Events = {};
    }

    E.Events.Map = {};
    E.Events.Map.initializing = 'ekylibre:map:events:initializing';
    E.Events.Map.new = {};
    E.Events.Map.new.complete = 'ekylibre:map:events:new:complete';
    E.Events.Map.new.cancel = 'ekylibre:map:events:new:cancel';
    E.Events.Map.ready = 'ekylibre:map:events:ready';
    E.Events.Map.edit = {};
    E.Events.Map.edit.change = 'ekylibre:map:events:edit:change';
    E.Events.Map.split = {};
    E.Events.Map.split.change = 'ekylibre:map:events:split:change';
    E.Events.Map.select = {};
    E.Events.Map.select.select = 'ekylibre:map:events:select:select';
    E.Events.Map.select.unselect = 'ekylibre:map:events:select:unselect';
    class Map {
        constructor(el, options) {
            this.el = el;
            if (options == null) {
                options = {};
            }
            $(this.el).trigger(E.Events.Map.initializing, this);
            this._cartography = new Cartography.Map(this.el, options);
            this.initHooks();
        }

        initHooks() {
            $(this._cartography.map).on(Cartography.Events.new.complete, function (e) {
                $(document).trigger(E.Events.Map.new.complete, e.originalEvent.data);
            });

            $(this._cartography.map).on(Cartography.Events.new.cancel, function () {
                $(document).trigger(E.Events.Map.new.cancel);
            });

            $(this._cartography.map).on(Cartography.Events.edit.change, (e) =>
                $(document).trigger(E.Events.Map.edit.change, e.originalEvent.data)
            );

            $(this._cartography.map).on(Cartography.Events.split.change, (e) =>
                $(document).trigger(E.Events.Map.split.change, e.originalEvent.data)
            );

            $(this._cartography.map).on(Cartography.Events.select.select, (e) =>
                $(document).trigger(E.Events.Map.select.select, e.originalEvent.data)
            );

            $(this._cartography.map).on(Cartography.Events.select.unselect, (e) =>
                $(document).trigger(E.Events.Map.select.unselect, e.originalEvent.data)
            );
        }

        addControl() {
            return this._cartography.addControl.apply(this._cartography, arguments);
        }

        getMap() {
            return this._cartography.getMap();
        }

        getZoom() {
            return this._cartography.map.getZoom();
        }

        getFeatureGroup(options = {}) {
            return this._cartography.getFeatureGroup(options);
        }

        boundingBox() {
            return this._cartography.map.getBounds().toBBoxString();
        }

        getBounds() {
            return this._cartography.map.getBounds();
        }

        fitBounds(bounds) {
            return this._cartography.map.fitBounds(bounds);
        }

        center() {
            this._cartography.center.apply(this._cartography, arguments);
        }

        edit() {
            return this._cartography.edit.apply(this._cartography, arguments);
        }

        destroy() {
            this._cartography.destroy.apply(this._cartography, arguments);
        }

        select() {
            return this._cartography.select.apply(this._cartography, arguments);
        }

        unselectMany() {
            this._cartography.unselectMany.apply(this._cartography, arguments);
        }

        unselect() {
            this._cartography.unselect.apply(this._cartography, arguments);
        }

        setView() {
            return this._cartography.setView.apply(this._cartography, arguments);
        }

        getMode() {
            return this._cartography.getMode.apply(this._cartography, arguments);
        }

        centerLayer() {
            return this._cartography.centerLayer.apply(this._cartography, arguments);
        }

        removeControl() {
            return this._cartography.removeControl.apply(this._cartography, arguments);
        }

        on(eventName, functionDefinition) {
            this._cartography.map.on(eventName, functionDefinition);
        }

        asyncLoading(url, onSuccess) {
            if (!url) {
                return;
            }

            return $.ajax({
                method: 'GET',
                dataType: 'json',
                url,
                beforeSend: () => {},
                success: (data) => {
                    return onSuccess.call(this, data);
                },
                error: () => {},
                complete: () => {},
            });
        }
    }

    E.Map = Map;

    E.onDomReady(function () {
        const baseElements = $('*[data-cartography]');
        if (baseElements.length == 0) return false;

        const $baseElement = baseElements.first();
        const options = $baseElement.data('cartography');
        if (options.type != undefined) {
            E.map = new E[`${options.type}Map`]($baseElement[0], options);
        } else {
            E.map = new Map($baseElement[0], options);
        }
    });
})(ekylibre, jQuery);
