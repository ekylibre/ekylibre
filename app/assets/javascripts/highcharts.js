(function ($, undefined) {
    "use strict";


    Highcharts.setOptions({
        chart: {
            style: {
                fontFamily: '"Open Sans", "Droid Sans", "Liberation Sans", Helvetica, sans-serif',
	        fontSize: '14px'
            }
        },
        credits: {
            enabled: false
        },
        tooltip: {
            enabled: true
        },
        legend: {
            enabled: false
        },
        title: {
            text: ''
        }
    });

    $.fn.highchartsFromData = function () {
        $(this).each(function () {
            var chart = $(this), options = {}, s, i, d;
            if (chart.prop('highchartLoaded') !== true) {
                options.chart = chart.data('highchart');
                //  OPTIONS: colors, credits, exporting, labels, legend, loading, navigation, pane, plot-options, series, subtitle, title, tooltip, x-axis, y-axis
                if (chart.data('highchartSeries') !== undefined)      options.series = chart.data('highchartSeries');
                if (chart.data('highchartColors') !== undefined)      options.colors = chart.data('highchartColors');
                if (chart.data('highchartCredits') !== undefined)     options.credits = chart.data('highchartCredits');
                if (chart.data('highchartExporting') !== undefined)   options.exporting = chart.data('highchartExporting');
                if (chart.data('highchartLabels') !== undefined)      options.labels = chart.data('highchartLabels');
                if (chart.data('highchartLegend') !== undefined)      options.legend = chart.data('highchartLegend');
                if (chart.data('highchartLoading') !== undefined)     options.loading = chart.data('highchartLoading');
                if (chart.data('highchartNavigation') !== undefined)  options.navigation = chart.data('highchartNavigation');
                if (chart.data('highchartPane') !== undefined)        options.pane = chart.data('highchartPane');
                if (chart.data('highchartPlotOptions') !== undefined) options.plotOptions = chart.data('highchartPlotOptions');
                if (chart.data('highchartSubtitle') !== undefined)    options.subtitle = chart.data('highchartSubtitle');
                if (chart.data('highchartTitle') !== undefined)       options.title = chart.data('highchartTitle');
                if (chart.data('highchartTooltip') !== undefined)     options.tooltip = chart.data('highchartTooltip');
                if (chart.data('highchartXAxis') !== undefined)       options.xAxis = chart.data('highchartXAxis');
                if (chart.data('highchartYAxis') !== undefined)       options.yAxis = chart.data('highchartYAxis');
                chart.highcharts(options);
                chart.prop('highchartLoaded', true);
                
                /* Convert date/datetime */
                if (false) { // (options.xAxis.type == "datetime" || options.xAxis.type == "date") {
                    for (s = 0; s < options.series.length; s++)  {
                    	// alert("L: " + options.series[s].data.length);
                        if (options.series[s].data && options.series[s].pointInterval === undefined) {
                            for (i = 0; i < options.series[s].data.length; i++) {
                            	d = new Date(options.series[s].data[i][0]);
                            	alert(d);
                            	d = Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), d.getUTCHours(), d.getUTCMinutes(), d.getUTCSeconds(), d.getUTCMilliseconds());
                            	// alert(d);
                                options.series[s].data[i][0] = d;                             
                                alert("D: " + options.series[s].data[i][0]);
                            }
                        }
                    }
                }

            }
        });
    };

    $.loadHighcharts = function() {
        $('*[data-highchart]').highchartsFromData();
    };

    $(document).ready($.loadHighcharts);

    $(document).on("page:load cocoon:after-insert cell:load", $.loadHighcharts);


})( jQuery );
