(function ($) {
    'use strict';

    const listControlledSelectorBtn = {
        handleSelectorBtn: function (model, $selectorBtnWrapper, conditions) {
            const $selectorInput = $selectorBtnWrapper.find('input[data-selector]');
            const $btn = $selectorBtnWrapper.children('a');
            this._bindInputs(model, $btn, $selectorInput, conditions);
        },

        _bindInputs: function (model, $btn, $selectorInput, conditions) {
            $(document).on('change', 'input[data-list-selector]', () => {
                const $selectedItems = this._getSelectedItems();
                const selectedItemsIds = this._getSelectedItemsIds($selectedItems);
                this._setBtnUrlParam(selectedItemsIds, $btn, model + '_ids');
                this._setDisabledProp($btn, $selectorInput, $selectedItems, conditions);
            });

            $selectorInput.on('selector:change', (_event, _selectedElement, was_initializing) => {
                if (!was_initializing) {
                    const paramName = $selectorInput.attr('id');
                    const selectedId = $($selectorInput[0]).selector('value')
                    const $selectedItems = this._getSelectedItems();
                    this._setBtnUrlParam([selectedId], $btn, paramName);
                    this._setDisabledProp($btn, $selectorInput, $selectedItems, conditions);
                }
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

        _setBtnUrlParam: function (values, $btn, param) {
            const urlRegex = new RegExp(`${param}=(\\d|,)+`);
            const linkUrl = $btn.attr('href');
            if (values.length > 0) {
                $btn.prop('href', linkUrl.replace(urlRegex, `${param}=${values.join(',')}`));
            }
        },

        _setDisabledProp: function ($btn, $selectorInput, $selectedItems, conditions) {
            this._setBtnDisabledProp($btn, $selectorInput, $selectedItems, conditions);
            this._setSelectorDisabledProp($selectorInput, $selectedItems, conditions);
        },

        _setBtnDisabledProp: function ($btn, $selectorInput, $selectedItems, conditions = []) {
            const enabled = [$selectedItems.length > 0, $selectorInput.val() != '']
                .concat(conditions.map((condition) => condition($selectedItems)))
                .every(Boolean);
            $btn.toggleClass('disabled', !enabled);
        },

        _setSelectorDisabledProp: function ($selectorInput, $selectedItems, conditions = []) {
            const enabled = [$selectedItems.length > 0].concat(conditions.map((condition) => condition($selectedItems))).every(Boolean);
            $selectorInput.prop('disabled', !enabled);
        },
    };

    $(document).ready(function () {
        const $selectorBtnWrapper = $('#autolink-incoming-harvest-to-intervention');
        if ($selectorBtnWrapper.length > 0) {
            listControlledSelectorBtn.handleSelectorBtn('incoming_harvest', $selectorBtnWrapper);
        }
    });
})(jQuery);
