(function ($) {
    'use strict';

    const listControlledBtn = {
        handleLink: function (model, third, $btn, conditions) {
            const linksUrls = [
                {
                    element: $btn,
                    url: $btn.prop('href'),
                },
            ];
            this._bindInputs(model, third, $btn, linksUrls, conditions);
        },

        _bindInputs: function (model, third, $btn, linksUrls, conditions) {
            $(document).on('change', 'input[data-list-selector]', () => {
                const $selectedItems = this._getSelectedItems();
                const selectedItemsIds = this._getSelectedItemsIds($selectedItems);
                this._setBtnUrl(selectedItemsIds, $btn, model, linksUrls);
                this._setDisabledProp($btn, $selectedItems, third, conditions);
            });
        },

        _getSelectedItems: function () {
            return $('input[data-list-selector]:checked').filter(function () {
                return /\d/.test($(this).data('list-selector'));
            });
        },

        _getSelectedItemsIds: function ($selectedItems) {
            return $selectedItems
                .map(function () {
                    return $(this).data('list-selector');
                })
                .toArray();
        },

        _checkThirdUniqueness: function ($selectedItems, third) {
            const selectedItemsThirdIds = $selectedItems
                .map(function () {
                    return $(this)
                        .closest('tr')
                        .data(third + 'Id');
                })
                .toArray();
            return _.uniq(_.compact(selectedItemsThirdIds)).length === 1;
        },

        _setBtnUrl: function (selectedItemsIds, _$btn, model, linksUrls) {
            const urlRegex = new RegExp(`${model}s\/(.*)\/`);
            for (const linkUrl of linksUrls) {
                if (selectedItemsIds.length > 0) {
                    $(linkUrl.element).prop('href', linkUrl.url.replace(urlRegex, `${model}s/${selectedItemsIds.join(',')}/`));
                }
            }
        },

        _setDisabledProp: function ($btn, $selectedItems, third, conditions) {
            const enabled = [$selectedItems.length > 0, this._checkThirdUniqueness($selectedItems, third)]
                .concat(conditions.map((condition) => condition($selectedItems)))
                .every(Boolean);
            $btn.toggleClass('disabled', !enabled);
        },
    };

    $(document).ready(function () {
        const invoiceable = function ($selectedItems) {
            return $selectedItems
                .map(function () {
                    return $(this).closest('tr').data('invoiceable?');
                })
                .toArray()
                .every(Boolean);
        };

        const conditions = [invoiceable];

        if ($('#shipments-list').length > 0) {
            listControlledBtn.handleLink('shipment', 'recipient', $('a#generate-invoice-btn'), conditions);
        }
    });

    $(document).ready(function () {
        const shippable = function ($selectedItems) {
            return $selectedItems
                .map(function () {
                    return $(this).closest('tr').data('shippable?');
                })
                .toArray()
                .every(Boolean);
        };

        const conditions = [shippable];

        if ($('#shipments-list').length > 0) {
            listControlledBtn.handleLink('shipment', 'recipient', $('a#ship-btn'), conditions);
        }
    });
})(jQuery);
