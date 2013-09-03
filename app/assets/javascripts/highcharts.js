(function ($, undefined) {
    "use strict";

    $.fn.highchartsFromData = function () {
        $(this).each(function () {
            var chart = $(this), options = {};
            if (chart.data('highchartLoaded') !== true) {
                options.chart = $.parseJSON(chart.data('highchart'));
                //  OPTIONS: colors, credits, exporting, labels, legend, loading, navigation, pane, plot-options, series, subtitle, title, tooltip, x-axis, y-axis
                if (chart.data('highchart-series') !== undefined) {
                    options.series = $.parseJSON(chart.data('highchart-series'))
                }
                if (chart.data('highchart-colors') !== undefined) {
                    options.colors = $.parseJSON(chart.data('highchart-colors'))
                }
                if (chart.data('highchart-credits') !== undefined) {
                    options.credits = $.parseJSON(chart.data('highchart-credits'))
                }
                if (chart.data('highchart-exporting') !== undefined) {
                    options.exporting = $.parseJSON(chart.data('highchart-exporting'))
                }
                if (chart.data('highchart-labels') !== undefined) {
                    options.labels = $.parseJSON(chart.data('highchart-labels'))
                }
                if (chart.data('highchart-legend') !== undefined) {
                    options.legend = $.parseJSON(chart.data('highchart-legend'))
                }
                if (chart.data('highchart-loading') !== undefined) {
                    options.loading = $.parseJSON(chart.data('highchart-loading'))
                }
                if (chart.data('highchart-navigation') !== undefined) {
                    options.navigation = $.parseJSON(chart.data('highchart-navigation'))
                }
                if (chart.data('highchart-pane') !== undefined) {
                    options.pane = $.parseJSON(chart.data('highchart-pane'))
                }
                if (chart.data('highchart-plot-options') !== undefined) {
                    options.plotOptions = $.parseJSON(chart.data('highchart-plot-options'))
                }
                if (chart.data('highchart-subtitle') !== undefined) {
                    options.subtitle = $.parseJSON(chart.data('highchart-subtitle'))
                }
                if (chart.data('highchart-title') !== undefined) {
                    options.title = $.parseJSON(chart.data('highchart-title'))
                }
                if (chart.data('highchart-tooltip') !== undefined) {
                    options.tooltip = $.parseJSON(chart.data('highchart-tooltip'))
                }
                if (chart.data('highchart-x-axis') !== undefined) {
                    options.xAxis = $.parseJSON(chart.data('highchart-x-axis'))
                }
                if (chart.data('highchart-y-axis') !== undefined) {
                    options.yAxis = $.parseJSON(chart.data('highchart-y-axis'))
                }
                chart.highchart(options);
                chart.data('highchartLoaded', true);
            }
        });
    };

    $.loadHighcharts = function() {
        $('*[data-highcharts]').highchartsFromData();
    };

    $(document).ready($.loadHighcharts);

    $(document).on("page:load cocoon:after-insert cell:load", $.loadHighcharts);
    
    
})( jQuery );
