(function ($) {
    $.fn.ready = function (callback) {
        $(this).on('turbolinks:load', callback)
    };
})(jQuery);