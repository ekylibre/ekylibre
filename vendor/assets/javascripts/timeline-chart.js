(function (global, factory) {
    if (typeof define === "function" && define.amd) {
        define(['module'], factory);
    } else if (typeof exports !== "undefined") {
        factory(module);
    } else {
        var mod = {
            exports: {}
        };
        factory(mod);
        global.TimelineChart = mod.exports;
    }
})(this, function (module) {
    'use strict';

    function _classCallCheck(instance, Constructor) {
        if (!(instance instanceof Constructor)) {
            throw new TypeError("Cannot call a class as a function");
        }
    }

    var _createClass = function () {
        function defineProperties(target, props) {
            for (var i = 0; i < props.length; i++) {
                var descriptor = props[i];
                descriptor.enumerable = descriptor.enumerable || false;
                descriptor.configurable = true;
                if ("value" in descriptor) descriptor.writable = true;
                Object.defineProperty(target, descriptor.key, descriptor);
            }
        }

        return function (Constructor, protoProps, staticProps) {
            if (protoProps) defineProperties(Constructor.prototype, protoProps);
            if (staticProps) defineProperties(Constructor, staticProps);
            return Constructor;
        };
    }();

    var TimelineChart = function () {

        var options, width, height;

        function TimelineChart(element, data, events, opts) {
            _classCallCheck(this, TimelineChart);

            var self = this;

            element.classList.add('timeline-chart');

            options = this.extendOptions(opts);

            var elementWidth = options.width || element.clientWidth;
            var elementHeight = options.height || element.clientHeight;

            var margin = {
                top: 0,
                right: 0,
                bottom: 20,
                left: 0
            };

            width = elementWidth - margin.left - margin.right;
            height = elementHeight - margin.top - margin.bottom;

            var groupWidth = 200;

            var x = d3.time.scale().domain([options.start_date, options.end_date]).range([groupWidth, width]);

            var xAxis = d3.svg.axis().scale(x).orient('bottom').tickSize(-height);

            TimelineChart.I18n.translateBar(d3, xAxis);

            var zoom = d3.behavior.zoom().x(x).on('zoom', zoomed);

            var svg = d3.select(element).append('svg').attr('width', width + margin.left + margin.right).attr('height', height + margin.top + margin.bottom).append('g').attr('transform', 'translate(' + margin.left + ',' + margin.top + ')').call(zoom);

            svg.append('defs').append('clipPath').attr('id', 'chart-content').append('rect').attr('x', groupWidth).attr('y', 0).attr('height', height).attr('width', width - groupWidth);

            svg.append('rect').attr('class', 'line-title-block').attr('x', 0).attr('y', 0).attr('height', height).attr('width', groupWidth);
            svg.append('rect').attr('class', 'chart-bounds').attr('x', groupWidth).attr('y', 0).attr('height', height).attr('width', width - groupWidth);

            svg.append('g').attr('class', 'x axis').attr('transform', 'translate(0,' + height + ')').call(xAxis);

            var groupHeight = height / data.length;
            var groupSection = svg.selectAll('.group-section').data(data).enter().append('line').attr('class', 'group-section').attr('x1', 0).attr('x2', width).attr('y1', function (d, i) {
                return groupHeight * (i + 1);
            }).attr('y2', function (d, i) {
                return groupHeight * (i + 1);
            });

            var groupLabels = svg.selectAll('.group-label').data(data).enter().append('text').attr('class', 'group-label').attr('x', 0).attr('y', function (d, i) {
                return groupHeight * i + groupHeight / 2 + 5.5;
            }).attr('dx', '0.5em').text(function (d) {
                return d.label;
            });

            var lineSection = svg.append('line').attr('x1', groupWidth).attr('x2', groupWidth).attr('y1', 0).attr('y2', height).attr('stroke', 'black');


            TimelineChart.Chart.addItems(x, svg, data, groupHeight);

            zoomed();

            TimelineChart.Events.initChartClick();
            TimelineChart.Events.initItemsEvents(events);

            function zoomed() {

                if (self.onVizChangeFn && d3.event) {
                    self.onVizChangeFn.call(self, {
                        scale: d3.event.scale,
                        translate: d3.event.translate,
                        domain: x.domain()
                    });
                }

                Zoom.editZoomTranslate(zoom, width, height, options);
                Zoom.refreshScale(svg, xAxis);
                Zoom.moveItems(svg, x, groupWidth);
            }
        }

        _createClass(TimelineChart, [{
            key: 'extendOptions',
            value: function extendOptions() {
                var ext = arguments.length <= 0 || arguments[0] === undefined ? {} : arguments[0];

                var defaultOptions = {
                    intervalMinWidth: 8, // px
                    tip: undefined,
                    textTruncateThreshold: 30
                };
                Object.keys(ext).map(function (k) {
                    return defaultOptions[k] = ext[k];
                });
                return defaultOptions;
            }
        }, {
            key: 'onVizChange',
            value: function onVizChange(fn) {
                this.onVizChangeFn = fn;
                return this;
            }
        }]);

        var Chart = {

            addItems: function(x, svg, data, groupHeight) {

                Chart._addIntervals(x, svg, data, groupHeight);
                Chart._addPoints(x, svg, data, groupHeight);
                Chart._addIcons(x, svg, data, groupHeight);
            },

            _addIntervals: function(x, svg, data, groupHeight) {

                var groupIntervalItems = Chart._getGroup(svg, '.group-interval-item', data, groupHeight, Chart._isInterval);

                var intervalBarHeight = 0.8 * groupHeight;
                var intervalBarMargin = (groupHeight - intervalBarHeight) / 2;

                groupIntervalItems.append('rect').attr('id', Chart._getCustomId())
                .attr('class', Chart._withCustom('interval'))
                .attr('width', function (d) {
                    return Math.max(options.intervalMinWidth, x(new Date(d.to)) - x(new Date(d.from)));
                }).attr('height', intervalBarHeight).attr('y', intervalBarMargin).attr('x', function (data) {
                    return Utils.getStartedDatePosition(x, data);
                });

                groupIntervalItems.append('text').text(Chart._getLabel).attr('fill', 'white')
                .attr('class', Chart._withCustom('interval-text')).attr('y', groupHeight - intervalBarHeight)
                .attr('x', function (data) {
                    return Utils.getStartedDatePosition(x, data);
                });
            },

            _addPoints: function(x, svg, data, groupHeight) {

                var groupDotItems = Chart._getGroup(svg, '.group-dot-item', data, groupHeight, Chart._isPoint);

                var dots = groupDotItems.append('circle').attr('class', Chart._withCustom('dot'))
                .attr('cx', function (data) {
                    return Utils.getDatePosition(x, data);
                }).attr('cy', groupHeight / 2).attr('r', 5);
            },

            _addIcons: function(x, svg, data, groupHeight) {

                var groupIconItems = Chart._getGroup(svg, '.group-icon-item', data, groupHeight, Chart._isIcon);

                var itemSize = 40;
                var iconHeight = (groupHeight - itemSize) / 2;

                groupIconItems.append('svg:foreignObject').attr('class', Chart._withCustom('icon'))
                .attr("width", itemSize)
                .attr("height", itemSize)
                .attr('x', function (data) {
                    return Utils.getDatePosition(x, data);
                }).attr('y', iconHeight)
                .html(function(d) {
                  return '<i class="picto picto-'+ d.icon +'"></i>';
                });
            },

            _getGroup: function(svg, groupClass, datas, groupHeight, filterCallBack) {

              return svg.selectAll(groupClass).data(datas).enter().append('g')
                .attr('clip-path', 'url(#chart-content)').attr('class', 'item')
                .attr('transform', function (d, i) {
                    return Chart._getTranslate(groupHeight, i);
                }).selectAll('.dot').data(function (d) {
                    return d.data.filter(filterCallBack);
                }).enter();
            },

            _isInterval: function(data) {
                return eval(data.type) === TimelineChart.TYPE.INTERVAL;
            },

            _isPoint: function(data) {
                return eval(data.type) === TimelineChart.TYPE.POINT;
            },

            _isIcon: function(data) {
                return eval(data.type) === TimelineChart.TYPE.ICON;
            },

            _getTranslate: function(groupHeight, i) {
                return 'translate(0, ' + groupHeight * i + ')';
            },

            _withCustom: function(defaultClass) {
                return function (d) {
                    return d.customClass ? [d.customClass, defaultClass].join(' ') : defaultClass;
                };
            },

            _getCustomId: function() {
                return function (d) {
                    return d.id;
                };
            },

            _getLabel: function(d) {
                return d.label;
            }
        };

        var Zoom = {

            editZoomTranslate: function(zoom, scaleWidth, scaleHeight, options) {

                if (Utils.isZoomOutOverLimit(zoom, options)) {
                  zoom.scale(TimelineChart.DEFAULT_ZOOM_SCALE);
                }

                var zoomTranslate = zoom.translate();
                var zoomScale = zoom.scale();

                var newXCoordinate = Zoom._calculNewCoordinate(scaleWidth, zoomScale, zoomTranslate[0]);
                var newYCoordinate = Zoom._calculNewCoordinate(scaleHeight, zoomScale, zoomTranslate[1]);

                zoom.translate([newXCoordinate, newYCoordinate]);
            },

            refreshScale: function(svg, xAxis) {

              svg.select('.x.axis').call(xAxis);
            },

            moveItems: function(svg, x, groupWidth) {

                Zoom._moveIntervals(svg, x);
                Zoom._movePoints(svg, x);
                Zoom._moveIcons(svg, x);
                Zoom._moveTexts(svg, x, groupWidth);
            },

            _moveIntervals: function(svg, x) {

                svg.selectAll('rect.interval').attr('x', function (data) {
                    return Utils.getStartedDatePosition(x, data);
                }).attr('width', function (d) {
                    return Math.max(options.intervalMinWidth, x(new Date(d.to)) - x(new Date(d.from)));
                });
            },

            _movePoints: function(svg, x) {

                svg.selectAll('circle.dot').attr('cx', function (data) {
                    return Utils.getDatePosition(x, data);
                });
            },

            _moveIcons: function(svg, x) {

                svg.selectAll('.item .icon').attr('x', function (data) {
                    return Utils.getDatePosition(x, data);
                });
            },

            _moveTexts: function(svg, x, groupWidth) {

                svg.selectAll('.interval-text').attr('x', function (data) {
                    var positionData = Zoom._getTextPositionData.call(this, data, x);
                    if (positionData.upToPosition - groupWidth - 10 < positionData.textWidth) {
                        return positionData.upToPosition;
                    } else if (positionData.xPosition < groupWidth && positionData.upToPosition > groupWidth) {
                        return groupWidth;
                    }
                    return positionData.xPosition;
                }).attr('text-anchor', function (data) {
                    var positionData = Zoom._getTextPositionData.call(this, data, x);
                    if (positionData.upToPosition - groupWidth - 10 < positionData.textWidth) {
                        return 'end';
                    }
                    return 'start';
                }).attr('dx', function (data) {
                    var positionData = Zoom._getTextPositionData.call(this, data, x);
                    if (positionData.upToPosition - groupWidth - 10 < positionData.textWidth) {
                        return '-0.5em';
                    }
                    return '0.5em';
                }).text(function (data) {
                    var positionData = Zoom._getTextPositionData.call(this, data, x);
                    var percent = (positionData.width - options.textTruncateThreshold) / positionData.textWidth;
                    if (percent < 1) {
                        if (positionData.width > options.textTruncateThreshold) {
                            return data.label.substr(0, Math.floor(data.label.length * percent)) + '...';
                        } else {
                            return '';
                        }
                    }

                    return data.label;
                });
            },

            _getTextPositionData: function(data, x) {

                this.textSizeInPx = this.textSizeInPx || this.getComputedTextLength();
                var from = x(new Date(data.from));
                var to = x(new Date(data.to));
                return {
                    xPosition: from,
                    upToPosition: to,
                    width: to - from,
                    textWidth: this.textSizeInPx
                };
            },

            _calculNewCoordinate: function(elementSize, zoomScale, zoomCoordinate) {
              return Math.min(0, Math.max(elementSize * (TimelineChart.DEFAULT_ZOOM_SCALE - zoomScale), zoomCoordinate));
            }
        };

        var Events = {

            initChartClick: function() {

                $('.chart-bounds').on('click', function() {
                    Events._removeMenu();
                });
            },

            initItemsEvents: function(events) {

                events.forEach(function(event) {

                    if (event) {

                        var objectKeys = Object.keys(event);

                        objectKeys.forEach(function(key) {

                            if (key !== "element_id") {

                                Events._addEventToChart(key, event);
                            }
                        });
                    }
                });
            },

            _addEventToChart: function(eventName, eventDatas) {

                var elementId = "#" + eventDatas.element_id;
                $(elementId).on(eventName, function(event) {

                      Events._removeMenu();

                      var content = $(eventDatas[eventName].content);

                      $(content).css('left', event.clientX);
                      $(content).css('top', event.clientY);

                      $('.timeline-chart').append(content);
                });
            },

            _removeMenu: function() {

                if ($('.timeline-chart nav').length > 0) {
                    $('.timeline-chart nav').remove();
                }
            }
        };

        var Utils = {

            getStartedDatePosition: function(x, data) {
                return x(new Date(data.from));
            },

            getDatePosition: function(x, data) {
                return x(new Date(data.at));
            },

            isOneDateOverLimits: function(x, options) {
                return isMinDateOverLimit(x, options) || isMaxDateOverLimit(x, options);
            },

            isDatesOverLimits: function(x, options) {
                return isMinDateOverLimit(x, options) && isMaxDateOverLimit(x, options);
            },

            isMinDateOverLimit: function(x, options) {

                var startDate = x.domain()[0];

                return startDate < options.start_date
                  || startDate > options.end_date;
            },

            isMaxDateOverLimit: function(x, options) {

              var endDate = x.domain()[1];

              return endDate < options.start_date
                || endDate > options.end_date;
            },

            isZoomOutOverLimit: function(zoom, options) {

                if (typeof options.zoom_out_limit === 'undefined') {
                    return false;
                }

                return zoom.scale() < options.zoom_out_limit;
            },

            isZoomInOverLimit: function(zoom, options) {

                if (typeof options.zoom_in_limit === 'undefined') {
                    return false;
                }

                return zoom.scale() < options.zoom_in_limit;
            },

            isMouseWheelDown: function() {
                return d3.event.sourceEvent.wheelDelta < 0;
            },

            isMouseWheelUp: function() {
                return d3.event.sourceEvent.wheelDelta > 0;
            }
        };

        var TimelineI18n = {

            translateBar: function(d3, axis) {
              axis.tickFormat(this._getTickFormat(d3, axis));
            },

            _getLocaleFormatter: function(d3) {

                return d3.locale({
                    "decimal": ",",
                    "thousands": ".",
                    "dateTime": I18n.ext.datetimeFormat.default(),
                    "date": I18n.ext.dateFormat.default(),
                    "time": I18n.ext.datetimeFormat.time(),
                    "periods": I18n.ext.datetime.periods(),
                    "days": I18n.ext.dates.getDayNames(),
                    "shortDays": I18n.ext.dates.getAbbrDayNames(),
                    "months": I18n.ext.dates.getMonthNames(),
                    "shortMonths": I18n.ext.dates.getAbbrMonthNames()
                });
            },

            _getTickFormat: function(d3, xAxis) {

                return this._getLocaleFormatter(d3).timeFormat.multi([
                    ["%H:%M", function(d) { return d.getMinutes(); }],
                    ["%H:%M", function(d) { return d.getHours(); }],
                    ["%a %d", function(d) { return d.getDay() && d.getDate() != 1; }],
                    ["%b %d", function(d) { return d.getDate() != 1; }],
                    ["%B", function(d) { return d.getMonth(); }],
                    ["%Y", function() { return true; }]
                ]);
            }
        };

        TimelineChart.Chart = Chart;
        TimelineChart.Zoom = Zoom;
        TimelineChart.Events = Events;
        TimelineChart.Utils = Utils;
        TimelineChart.I18n = TimelineI18n;

        return TimelineChart;
    }();

    TimelineChart.TYPE = {
        POINT: Symbol(),
        INTERVAL: Symbol(),
        ICON: Symbol()
    };

    TimelineChart.DEFAULT_ZOOM_SCALE = 1;
    TimelineChart.DEFAULT_ZOOM_TRANSLATE = [0,0];

    module.exports = TimelineChart;
});
