((E, $) ->
  'use strict'

  $(document).ready ->

    class ChartVueJs
      contructor: (chartType, chartOptions) ->
        Vue.component chartType, chartOptions

    class VueBarChart extends ChartVueJs
      contructor: ->
      Vue.component 'bar-chart',
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

        this.data.datasets.forEach (dataset, indexDataset) ->
          meta = chartInstance.controller.getDatasetMeta(indexDataset)
          meta.data.forEach (bar, indexData) ->
            data = dataset.data[indexData]
            barHeight = bar._model.y - bar._model.base
            centerY = bar._model.base + (barHeight / 2)

            ctx.fillText(data, bar._model.x, centerY)


    E.VueBarChart = VueBarChart

) ekylibre, jQuery
