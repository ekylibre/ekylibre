/**
 * @author Hugo
 */
/**
* Created: vogdb Date: 4/30/13 Time: 6:07 PM
*/

L.Control.SelectLayers = L.Control.ActiveLayers.extend ({

  _initLayout: function () {
    var className = 'leaflet-control-layers'
    var container = this._container = L.DomUtil.create('div', className)

    L.DomEvent.disableClickPropagation(container)
    if (!L.Browser.touch) {
      L.DomEvent.on(container, 'mousewheel', L.DomEvent.stopPropagation)
    } else {
      L.DomEvent.on(container, 'click', L.DomEvent.stopPropagation)
    }

    var form = this._form = L.DomUtil.create('form', className + '-list')

    if (this.options.collapsed) {
      var link = this._layersLink = L.DomUtil.create('a', className + '-toggle', container)
      link.href = '#'
      link.title = 'Layers'

      if (L.Browser.touch) {
        L.DomEvent
          .on(link, 'click', L.DomEvent.stopPropagation)
          .on(link, 'click', L.DomEvent.preventDefault)
          .on(link, 'click', this._expand, this)
      } else {
        L.DomEvent
          .on(container, 'mouseover', this._expand, this)
          .on(container, 'mouseout', this._collapse, this)
        L.DomEvent.on(link, 'focus', this._expand, this)
      }

      this._map.on('movestart', this._collapse, this)
    } else {
      this._expand()
    }

    this._baseLayersList = L.DomUtil.create('select', className + '-base', form)
    L.DomEvent.on(this._baseLayersList, 'change', this._onBaseLayerOptionChange, this)

    this._separator = L.DomUtil.create('div', className + '-separator', form)

    this._overlaysList = L.DomUtil.create('select', className + '-overlays', form)
    this._overlaysList.setAttribute('multiple', true)
    //extend across the width of the container
    this._overlaysList.style.width = '100%'
    L.DomEvent.on(this._overlaysList, 'change', this._onOverlayLayerOptionChange, this)

    container.appendChild(form)
  }

  ,_onBaseLayerOptionChange: function () {
    var selectedLayerIndex = this._baseLayersList.selectedIndex
    var selectedLayerOption = this._baseLayersList.options[selectedLayerIndex]
    var selectedLayer = this._layers[selectedLayerOption.layerId]

    this._changeBaseLayer(selectedLayer)
  }

  ,_changeBaseLayer: function (layerObj) {
    this._handlingClick = true

    this._map.addLayer(layerObj.layer)
    this._map.removeLayer(this._activeBaseLayer.layer)
    this._map.setZoom(this._map.getZoom())
    this._map.fire('baselayerchange', {layer: layerObj.layer})
    this._activeBaseLayer = layerObj

    this._handlingClick = false
  }

  ,_onOverlayLayerOptionChange: function (e) {
    //Note. Don't try to implement this function through .selectedIndex
    //or delegation of click event. These methods have bunch of issues on Android devices.
    this._handlingClick = true

    var options = this._overlaysList.options
    for (var i = 0; i < options.length; i++) {
      var option = options[i]
      var layer = this._layers[option.layerId].layer
      if (option.selected) {
        if (!this._map.hasLayer(layer)) {
          this._map.addLayer(layer)
        }
      } else {
        if (this._map.hasLayer(layer)) {
          this._map.removeLayer(layer)
        }
      }
    }

    this._handlingClick = false
  }

  ,_addItem: function (obj) {
    var option = this._createOptionElement(obj)
    if (obj.overlay) {
      this._overlaysList.appendChild(option)
    } else {
      this._baseLayersList.appendChild(option)
    }
  }

  ,_createOptionElement: function (obj) {
    var option = document.createElement('option')
    option.layerId = L.stamp(obj.layer)
    option.innerHTML = obj.name
    if (this._map.hasLayer(obj.layer)) {
      option.setAttribute('selected', true)
    }
    return option
  }

  ,_collapse: function (e) {
    if (e.target === this._container) {
      L.Control.Layers.prototype._collapse.apply(this, arguments)
    }
  }

})

L.control.selectLayers = function (baseLayers, overlays, options) {
  return new L.Control.SelectLayers(baseLayers, overlays, options)
}