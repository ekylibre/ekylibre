((E, $) ->
  'use strict'

  $(document).ready ->
    Vue.component 'bar-chart',
      extends: VueChartJs.Bar,
      props: ['options'],
      mixins: [VueChartJs.mixins.reactiveProp],
      mounted: ->
        this.renderChart(this.chartData, this.options)


    vm = new Vue({
      el: '#test',
      data: {
        chartData: {},
        chartOptions: {}
      }
      mounted: ->
        this.fillData()
        this.fillOptions()
      methods:
        fillData: ->
          this.chartData = {
            labels: ['Janvier', 'Février', 'Mars']
            datasets: [
              {
                label: 'Data One',
                backgroundColor: '#f87979',
                data: [10, 20, 50]
              },
              {
                label: 'Data two',
                backgroundColor: '#2196F3',
                data: [15, 30, 70]
              },
              {
                label: 'Data two',
                backgroundColor: '#4CAF50',
                data: [25, 160, 250]
              },
              {
                label: 'Data two',
                backgroundColor: '#795548',
                data: [100, 200, 270]
              },
              {
                label: 'Data two',
                backgroundColor: '#9C27B0',
                data: [120, 180, 300]
              }
            ]
          }
        fillOptions: ->
          this.chartOptions = {
            legend: {
              display: false
            }
            barValueSpacing: 20,
            scales: {
             yAxes: [{
               ticks: {
                 min: 0,
               }
             }]
            }
            responsive: true,
            maintainAspectRatio: false,
            onClick: ->
              #alert('Yay!')
          }
    })


) ekylibre, jQuery
