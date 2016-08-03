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
        function TimelineChart(element, data, opts) {
            _classCallCheck(this, TimelineChart);

            var self = this;

            element.classList.add('timeline-chart');

            var options = this.extendOptions(opts);

            var allElements = data.reduce(function (agg, e) {
                return agg.concat(e.data);
            }, []);

            var minDt = d3.min(allElements, this.getPointMinDt);
            var maxDt = d3.max(allElements, this.getPointMaxDt);

            var elementWidth = options.width || element.clientWidth;
            var elementHeight = options.height || element.clientHeight;

            var margin = {
                top: 0,
                right: 0,
                bottom: 20,
                left: 0
            };

            var width = elementWidth - margin.left - margin.right;
            var height = elementHeight - margin.top - margin.bottom;

            var groupWidth = 200;

            var x = d3.time.scale().domain([minDt, maxDt]).range([groupWidth, width]);

            var xAxis = d3.svg.axis().scale(x).orient('bottom').tickSize(-height);

            var i18n = I18n.translations["fra"];

            var localeFormatter = d3.locale({
                "decimal": ",",
                "thousands": ".",
                "grouping": [3],
                "currency": ["€", ""],
                "dateTime": "%a %b %e %X %Y",
                "date": "%d-%m-%Y",
                "time": "%H:%M:%S",
                "periods": ["AM", "PM"],
                "days": ["Zondag", "Maandag", "Dinsdag", "Woensdag", "Donderdag", "Vrijdag", "Zaterdag"],
                "shortDays": ["Zo", "Ma", "Di", "Wo", "Do", "Vr", "Za"],
                "months": ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"],
                "shortMonths": ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dec"]
            })

            var tickFormat = localeFormatter.timeFormat.multi([
                ["%H:%M", function(d) { return d.getMinutes(); }],
                ["%H:%M", function(d) { return d.getHours(); }],
                ["%a %d", function(d) { return d.getDay() && d.getDate() != 1; }],
                ["%b %d", function(d) { return d.getDate() != 1; }],
                ["%B", function(d) { return d.getMonth(); }],
                ["%Y", function() { return true; }]
            ]);

            xAxis.tickFormat(tickFormat);







            var zoom = d3.behavior.zoom().x(x).on('zoom', zoomed);

            var svg = d3.select(element).append('svg').attr('width', width + margin.left + margin.right).attr('height', height + margin.top + margin.bottom).append('g').attr('transform', 'translate(' + margin.left + ',' + margin.top + ')').call(zoom);

            svg.append('defs').append('clipPath').attr('id', 'chart-content').append('rect').attr('x', groupWidth).attr('y', 0).attr('height', height).attr('width', width - groupWidth);

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

            var groupIntervalItems = svg.selectAll('.group-interval-item').data(data).enter().append('g').attr('clip-path', 'url(#chart-content)').attr('class', 'item').attr('transform', function (d, i) {
                return 'translate(0, ' + groupHeight * i + ')';
            }).selectAll('.dot').data(function (d) {
                return d.data.filter(function (_) {
                    return _.type === TimelineChart.TYPE.INTERVAL;
                });
            }).enter();

            var intervalBarHeight = 0.8 * groupHeight;
            var intervalBarMargin = (groupHeight - intervalBarHeight) / 2;
            var intervals = groupIntervalItems.append('rect').attr('class', withCustom('interval')).attr('width', function (d) {
                return Math.max(options.intervalMinWidth, x(d.to) - x(d.from));
            }).attr('height', intervalBarHeight).attr('y', intervalBarMargin).attr('x', function (d) {
                return x(d.from);
            });

            var intervalTexts = groupIntervalItems.append('text').text(function (d) {
                return d.label;
            }).attr('fill', 'white').attr('class', withCustom('interval-text')).attr('y', groupHeight / 2 + 5).attr('x', function (d) {
                return x(d.from);
            });

            var groupDotItems = svg.selectAll('.group-dot-item').data(data).enter().append('g').attr('clip-path', 'url(#chart-content)').attr('class', 'item').attr('transform', function (d, i) {
                return 'translate(0, ' + groupHeight * i + ')';
            }).selectAll('.dot').data(function (d) {
                return d.data.filter(function (_) {
                    return _.type === TimelineChart.TYPE.POINT;
                });
            }).enter();

            var dots = groupDotItems.append('circle').attr('class', withCustom('dot')).attr('cx', function (d) {
                return x(d.at);
            }).attr('cy', groupHeight / 2).attr('r', 5);

            if (options.tip) {
                if (d3.tip) {
                    var tip = d3.tip().attr('class', 'd3-tip').html(options.tip);
                    svg.call(tip);
                    dots.on('mouseover', tip.show).on('mouseout', tip.hide);
                } else {
                    console.error('Please make sure you have d3.tip included as dependency (https://github.com/Caged/d3-tip)');
                }
            }

            zoomed();

            if (options.lock_zoom) {
                d3.select('svg').on('mousedown.zoom',null);
                d3.select('svg').on('touchstart.zoom',null);
                d3.select('svg').on('touchmove.zoom',null);
                d3.select('svg').on('touchend.zoom',null);
            }


            function withCustom(defaultClass) {
                return function (d) {
                    return d.customClass ? [d.customClass, defaultClass].join(' ') : defaultClass;
                };
            }

            function zoomed() {
                if (self.onVizChangeFn && d3.event) {
                    self.onVizChangeFn.call(self, {
                        scale: d3.event.scale,
                        translate: d3.event.translate,
                        domain: x.domain()
                    });
                }

                svg.select('.x.axis').call(xAxis);

                svg.selectAll('circle.dot').attr('cx', function (d) {
                    return x(d.at);
                });
                svg.selectAll('rect.interval').attr('x', function (d) {
                    return x(d.from);
                }).attr('width', function (d) {
                    return Math.max(options.intervalMinWidth, x(d.to) - x(d.from));
                });

                svg.selectAll('.interval-text').attr('x', function (d) {
                    var positionData = getTextPositionData.call(this, d);
                    if (positionData.upToPosition - groupWidth - 10 < positionData.textWidth) {
                        return positionData.upToPosition;
                    } else if (positionData.xPosition < groupWidth && positionData.upToPosition > groupWidth) {
                        return groupWidth;
                    }
                    return positionData.xPosition;
                }).attr('text-anchor', function (d) {
                    var positionData = getTextPositionData.call(this, d);
                    if (positionData.upToPosition - groupWidth - 10 < positionData.textWidth) {
                        return 'end';
                    }
                    return 'start';
                }).attr('dx', function (d) {
                    var positionData = getTextPositionData.call(this, d);
                    if (positionData.upToPosition - groupWidth - 10 < positionData.textWidth) {
                        return '-0.5em';
                    }
                    return '0.5em';
                }).text(function (d) {
                    var positionData = getTextPositionData.call(this, d);
                    var percent = (positionData.width - options.textTruncateThreshold) / positionData.textWidth;
                    if (percent < 1) {
                        if (positionData.width > options.textTruncateThreshold) {
                            return d.label.substr(0, Math.floor(d.label.length * percent)) + '...';
                        } else {
                            return '';
                        }
                    }

                    return d.label;
                });

                function getTextPositionData(d) {
                    this.textSizeInPx = this.textSizeInPx || this.getComputedTextLength();
                    var from = x(d.from);
                    var to = x(d.to);
                    return {
                        xPosition: from,
                        upToPosition: to,
                        width: to - from,
                        textWidth: this.textSizeInPx
                    };
                }
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
            key: 'getPointMinDt',
            value: function getPointMinDt(p) {
                return p.type === TimelineChart.TYPE.POINT ? p.at : p.from;
            }
        }, {
            key: 'getPointMaxDt',
            value: function getPointMaxDt(p) {
                return p.type === TimelineChart.TYPE.POINT ? p.at : p.to;
            }
        }, {
            key: 'onVizChange',
            value: function onVizChange(fn) {
                this.onVizChangeFn = fn;
                return this;
            }
        }]);

        return TimelineChart;
    }();

    TimelineChart.TYPE = {
        POINT: Symbol(),
        INTERVAL: Symbol()
    };

    module.exports = TimelineChart;
});
//# sourceMappingURL=timeline-chart.js.map
