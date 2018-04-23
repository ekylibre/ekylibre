// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require modernizr
//= require jquery
//= require jquery/jquery.lazy
//= require jquery-ui/widgets/datepicker
//= require jquery-ui/i18n/datepicker-fr
// require jquery-ui/i18n/datepicker-ar
// require jquery-ui/i18n/datepicker-ja
//= require jquery-ui/widgets/dialog
//= require jquery-ui/widgets/slider
//= require jquery-ui/widgets/accordion
//= require jquery-ui/widgets/sortable
//= require jquery-ui/widgets/droppable
//= require jquery_ujs
//= require jquery.remotipart
//= require jquery.turbolinks
//= require turbolinks
//= require active_list.jquery
//= require knockout
//= require_self
//= require i18n
//= require i18n/translations
//= require i18n/locale
//= require i18n/ext
//= require wice_grid
//= require wice_grid/settings
//= require ekylibre
//= require moment
//= require moment/ar
//= require moment/de
//= require moment/es
//= require moment/fr
//= require moment/it
//= require moment/ja
//= require moment/pt
//= require moment/zh-cn
//= require bootstrap-datetimepicker
//= require formize/behave
//= require form/dialog
//= require formize/observe
//= require form/scope
//= require form/dependents
//= require form/toggle
//= require form/dates
//= require form/links
//= require cocoon
//= require jquery/ext
//= require selector
//= require ui
//= require jstz
//= require heatmap
//= require geographiclib
//= require leaflet.js.erb
//= require leaflet/draw
//= require leaflet/fullscreen
//= require leaflet/providers
//= require leaflet/heatmap
//= require leaflet/measure
//= require leaflet/easy-button
//= require leaflet/modal
//= require leaflet/label
//= require d3
//= require d3/tip
//= require timeline-chart.js
//= require rbush
//= require autosize
//= require plugins
//= require_tree .
//= require tour
//= require bootstrap-slider

//= require vue


var visualization = {};
var mapeditor = {};
var ekylibre = {};
var calcul = {};

var golumn = {};

// FIX Browser interoperability
// href function seems to be ineffective
$.rails.href = function (element) {
  return $(element).attr('href');
}

Turbolinks.enableTransitionCache();
Turbolinks.enableProgressBar();

$(document).ready(function()
{
    L.Icon.Default.imagePath = '/assets';
});
