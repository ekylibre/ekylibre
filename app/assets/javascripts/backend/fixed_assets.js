(function (E, $) {
    'use strict';
    $(document).ready(function () {
        $("a.state-bar__state[data-name='fixed_asset_sold']").on('click', function (event) {
            if ($('#selling-actions-modal').data('sale-id')) {
                return;
            }
            event.preventDefault();
            event.stopPropagation();
            $('#selling-actions-modal').modal('show');
        });
        $('#submit-form').on('click', function (event) {
            if ($('select#fixed_asset_sale_item_id').val()) {
                $('#selling-actions-modal').find('form').submit();
            }
        });
        $('select#fixed_asset_sale_item_id').on('change', function (_event) {
            $('#selling-actions-modal').find('#submit-form').prop('disabled', !!!$('select#fixed_asset_sale_item_id').val());
        });
    });

    $(document).on('change', "input[type='checkbox'][data-show='#assets']", function (event) {
        const $quantityInput = $(this).closest('.nested-fields').find("input[data-trade-component='quantity']");
        if ($(this).is(':checked')) {
            $quantityInput.prop('disabled', true);
            $quantityInput.val(1);
            $quantityInput.trigger('change');
        } else {
            $quantityInput.prop('disabled', false);
        }
    });

    function yearToPercent(year) {
        return Math.round((1 / year) * 100 * 100) / 100;
    }

    function percentToYear(percent) {
        return Math.round((1 / (percent / 100)) * 100) / 100;
    }

    function handleDepreciationConversion(element) {
        const depreciationPercentageInput = element.querySelector('#fixed_asset_depreciation_percentage');
        const depreciationPeriodInput = element.querySelector('#fixed_asset_depreciation_period');

        if (depreciationPercentageInput.value) {
            depreciationPeriodInput.value = percentToYear(depreciationPercentageInput.value);
        }

        depreciationPercentageInput.addEventListener('focusout', function () {
            if (this.value == 0) {
                this.value = 0.01;
            }
            depreciationPeriodInput.value = percentToYear(this.value);
        });

        depreciationPeriodInput.addEventListener('focusout', function () {
            if (this.value == 0) {
                this.value = 0.01;
            }
            depreciationPercentageInput.value = yearToPercent(this.value);
        });
    }

    E.onDomReady(function () {
        const linearOptionsFieldSet = document.querySelector("form[id*='fixed_asset'] #linear_options");
        if (linearOptionsFieldSet != null) {
            handleDepreciationConversion(linearOptionsFieldSet);
        }
    });
})(ekylibre, jQuery);
