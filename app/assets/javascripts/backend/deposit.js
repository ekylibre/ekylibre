(function (E) {
    class DepositablePaymentsList {
        constructor(element) {
            this.list = element;
            this.createButton = element.querySelector('input.primary');
            this.createButtonValue = this.createButton.value
        }

        setButtonValue(){
            this.createButton.value = `${this.createButtonValue} (${this.selectedIds.length})`
        };

        changeValue(){
            this.listSelectorInputs.forEach((input) => {
                input.addEventListener('change', ()=> {
                    this.setButtonValue()
                });
            });
        };

        init() {
            this.setButtonValue()
            this.changeValue()

            $(document).on('list:page:change', () => {
                this.setButtonValue()
                this.changeValue()
            })
        }

        get listSelectorInputs() {
            return this.list.querySelectorAll('input#deposit_payment_ids_');
        }

        get selectedIds() {
            return [...this.listSelectorInputs]
                .filter((input) => input.checked);
        };
    }

    E.onDomReady(function () {
        const element = document.querySelector('#new_deposit');
        if (element !== null) {
            new DepositablePaymentsList(element).init();
        }
    });
})(ekylibre);