(($) ->
  'use strict'

  $(document).ready ->
    element = document.getElementById('chart')
    datas = [{
            label: 'Périodes',
            data: [{
                label: 'I\'m a label with a custom class',
                type: TimelineChart.TYPE.INTERVAL,
                from: new Date([2015, 2, 1]),
                to: new Date([2015, 3, 1]),
                customClass: 'blue-interval'
            }, {
                label: 'I\'m a label with a custom class',
                type: TimelineChart.TYPE.INTERVAL,
                from: new Date([2015, 2, 20]),
                to: new Date([2015, 3, 1]),
                customClass: 'blue-interval'
            }]
        }, {
            label: 'Interventions',
            data: [{
                label: 'Label 1',
                type: TimelineChart.TYPE.INTERVAL,
                from: new Date([2015, 1, 15]),
                to: new Date([2015, 3, 1])
            }, {
                label: 'Label 2',
                type: TimelineChart.TYPE.INTERVAL,
                from: new Date([2015, 4, 1]),
                to: new Date([2015, 5, 12])
            }]
        }];

    timeline = new TimelineChart(element, datas, {
      lock_zoom: true
    });

) jQuery
