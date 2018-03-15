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


      addValueInBar: (chart) ->
        ctx = chart.ctx
        ctx.textAlign = 'center'
        ctx.fillStyle = "rgba(0, 0, 0, 1)"
        ctx.textBaseline = 'bottom'

        chart.data.datasets.forEach (dataset, indexDataset) ->
          meta = chart.controller.getDatasetMeta(indexDataset)
          meta.data.forEach (bar, indexData) ->
            data = dataset.data[indexData]
            barHeight = bar._model.y - bar._model.base
            centerY = bar._model.base + (barHeight / 2)

            ctx.fillText(data, bar._model.x, centerY)


    E.VueBarChart = VueBarChart

) ekylibre, jQuery
