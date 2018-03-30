((E, $) ->
  'use strict'

  $(document).ready ->

    class ChartVueJs
      constructor: (chartType, chartOptions) ->
        Vue.component chartType, chartOptions

    class VueBarChart extends ChartVueJs
      constructor: ->
        super 'bar-chart',
          extends: VueChartJs.Bar,
          props: ['options'],
          mixins: [VueChartJs.mixins.reactiveProp],
          mounted: ->
            this.renderChart(this.chartData, this.options)


      addValuesInBars: (chart, textColor) ->
        self = this

        chart.data.datasets.forEach (dataset, indexDataset) ->
          meta = chart.controller.getDatasetMeta(indexDataset)

          unless meta.hidden
            meta.data.forEach (bar, indexData) ->
              data = dataset.data[indexData]
              self._drawText(chart, bar, data, textColor)


      addValueInBar: (chart, textColor, datasetIndex, barIndex) ->
        dataset = chart.data.datasets[datasetIndex]
        data = dataset.data[barIndex]
        meta = chart.controller.getDatasetMeta(datasetIndex)

        return if meta.hidden

        bar = meta.data[barIndex]

        this._drawText(chart, bar, data, textColor)


      changeBarColor: (chart, bar, color) ->
        barDatasetIndex = bar._datasetIndex
        barIndex = bar._index

        meta = chart.controller.getDatasetMeta(barDatasetIndex)
        data = meta.data[barIndex]
        barConfiguration = data._chart.config.data

        barConfiguration.datasets[barDatasetIndex].backgroundColor[barIndex] = color

        chart.update()


      changeDatasetColors: (chart, datasets) ->
        chart.data.datasets.forEach (dataset, indexDataset) ->
          dataset.backgroundColor = datasets[indexDataset].backgroundColor


      _drawText: (chart, bar, text, textColor) ->
        context = this._getContext(chart, textColor)

        barHeight = bar._model.y - bar._model.base
        centerY = bar._model.base + (barHeight / 2)
        context.fillText(text, bar._model.x, centerY)


      _getContext: (chart, textColor, textAlign = 'center', textBaseline = 'bottom') ->
        context = chart.ctx

        context.textAlign = textAlign
        context.fillStyle = textColor
        context.textBaseline = textBaseline

        context


    E.VueBarChart = VueBarChart

) ekylibre, jQuery
