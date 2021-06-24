(function (E, $) {
    class CropGroupForm {
        constructor(element) {
            this.element = element;
            this.targetTypeInput = element.querySelectorAll("input[type=radio][name='crop_group[target]']");
            this.$cocoonCropContainer = $(element.querySelector('.crop-group-item-fields'));
            this.labelUnrolls = element.querySelectorAll('input[id^="crop_group_labellings_attributes_"][id$="_label_id"]');
            this.$cocoonLabelContainer = $(element.querySelector('#labellings-field'));
        }

        init() {
            this.handleRadioButonsState();
            this.updateCropTypes();
            this.updateCropScopes();

            this.targetTypeInput.forEach((input) =>
                input.addEventListener('change', () => {
                    this.updateCropTypes();
                    this.updateCropScopes();
                })
            );

            this.$cocoonCropContainer.on('cocoon:after-insert', () => {
                this.updateCropTypes();
                this.updateCropScopes();
            });

            this.$cocoonCropContainer.on('cocoon:after-remove', () => {
                this.handleRadioButonsState();
            });

            this.cropsTargetUnrolls.forEach((unroll) =>
                unroll.addEventListener('unroll:selector:change', () => {
                    this.handleRadioButonsState();
                })
            );

            this.labelUnrolls.forEach((unroll) => this.bindLabelUnrolls(unroll));

            this.$cocoonLabelContainer.on('cocoon:after-insert', (_e, insertedItem) => {
                const unroll = insertedItem.find('input[id^="crop_group_labellings_attributes_"][id$="_label_id"]')[0];
                this.bindLabelUnrolls(unroll);
            });
        }

        bindLabelUnrolls(unroll) {
            unroll.addEventListener('unroll:selector:change', (e) => {
                const linkToConf = e.detail.unroll.element.parent().siblings('a')[0];
                linkToConf.href = `/backend/labels/${e.detail.unroll.id}/edit`;
                linkToConf.style.display = 'inline-block';
            });
        }

        get selectedTargetType() {
            return [...this.targetTypeInput].filter((input) => input.checked)[0].value;
        }

        get selectedCropsCount() {
            return [...this.element.querySelectorAll("input[name$='[crop_id]']")].filter((input) => input.value !== '').length;
        }

        get cropsTargetUnrolls(){
            return this.element.querySelectorAll('input[id^="crop_group_items_attributes_"][id$="_crop_id"]');
        }

        get cropsTargetTypeInputs(){
            return this.element.querySelectorAll('input[id^="crop_group_items_attributes_"][id$="_crop_type"]');
        }

        handleRadioButonsState() {
            const radio_button = [...this.targetTypeInput].filter((input) => !input.checked)[0];
            if (this.selectedCropsCount > 0) {
                radio_button.disabled = true;
            } else {
                radio_button.disabled = false;
            }
        }

        updateCropTypes() {
            const cropType = _.startCase(_.camelCase(this.selectedTargetType)).replace(/ /g, '');
            this.cropsTargetTypeInputs.forEach((input) => (input.value = cropType));
        }
        updateCropScopes() {
            const scopeName = this.selectedTargetType + 's';
            const productsUnrollUrl = '/backend/products/unroll?scope=';
            this.cropsTargetUnrolls.forEach((input) => (input.dataset.selector = productsUnrollUrl + scopeName));
        }
    }

    E.onDomReady(function () {
        const element = document.querySelector('form#new_crop_group, form[id^=edit_crop_group]');
        if (element !== null) {
            new CropGroupForm(element).init();
        }
    });
})(ekylibre, jQuery);
