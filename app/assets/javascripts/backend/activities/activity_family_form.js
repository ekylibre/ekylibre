(function (E, $) {
    class ActivityFamilyForm {
        constructor($formElement) {
            this.familyInput = $formElement.find('select#activity_family');
            this.$submitButton = $formElement.find('#activity_family_submit');

            this.submitButtonHref = this.$submitButton.attr('href');
        }

        init() {
            this.familyInput.on('change', (event) => {
                if (event.target.value != null && event.target.value !== '') {
                    this.updateSubmitButton(event.target.value);
                } else {
                    this.disableSubmitButton();
                }
            });
        }

        updateSubmitButton(family) {
            this.$submitButton.attr('href', this.submitButtonHref + ('&family=' + family));
            this.enableSubmitButton();
        }

        enableSubmitButton() {
            this.$submitButton.attr('disabled', false);
        }

        disableSubmitButton() {
            this.$submitButton.attr('disabled', true);
        }
    }

    E.onDomReady(function () {
        const $formElement = $('form#new_activity');
        if ($formElement.length === 0 || $('select#activity_family').val() !== '') {
            return;
        }

        new ActivityFamilyForm($formElement).init();
    });
})(ekylibre, jQuery);
