(($) ->
  'use strict'

  $(document).ready ->
    element = document.getElementById('chart')
    datas = [{
            label: 'Périodes',
            data: [{
                label: 'I\'m a label with a custom class',
                type: TimelineChart.TYPE.INTERVAL,
                id: "interval1",
                from: new Date([2016, 2, 1]),
                to: new Date([2016, 3, 1]),
                customClass: 'blue-interval'
                onClick: (event) ->
                    $('.interval-menu').css('left', event.clientX)
                    $('.interval-menu').css('top', event.clientY)
                    $('.interval-menu').removeClass('hidden')
            }, {
                label: 'I\'m a label with a custom class',
                type: TimelineChart.TYPE.INTERVAL,
                id: "interval2",
                from: new Date([2016, 2, 20]),
                to: new Date([2016, 3, 1]),
                customClass: 'blue-interval'
            }]
        }, {
            label: 'Interventions',
            data: [{
                label: 'Label 1',
                type: TimelineChart.TYPE.INTERVAL,
                id: "interval3",
                from: new Date([2016, 1, 15]),
                to: new Date([2016, 3, 1])
                customClass: 'blue-interval'
                onClick: (event) ->
                    $('.interval-menu').css('left', event.clientX)
                    $('.interval-menu').css('top', event.clientY)
                    $('.interval-menu').removeClass('hidden')
            }, {
                label: 'Label 2',
                type: TimelineChart.TYPE.INTERVAL,
                id: "interval4",
                from: new Date([2016, 4, 1]),
                to: new Date([2016, 10, 12])
                customClass: 'blue-interval'
            }]
        }];

    timeline = new TimelineChart(element, datas, {
      tip: (d) ->
          return d.at || d.from + '<br>' + d.to
      lock_zoom: true,
      start_date: new Date(2015,3,3),
      end_date: new Date(2016,13,10),
      zoom_out_limit: TimelineChart.DEFAULT_ZOOM_SCALE
    }).onVizChange((e) -> console.log(e));

) jQuery
