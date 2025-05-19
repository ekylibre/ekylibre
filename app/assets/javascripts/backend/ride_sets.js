(function (E) {
    class RideSetGroups {
        constructor(element) {
            this.list = element;
            this.listSelectorInputs = element.querySelectorAll('input[data-list-selector]');
            this.deleteSelectedRideSetBtn = document.querySelector('#selected-ride-sets');
            this.deleteSelectedRideSetBtnUrl = this.deleteSelectedRideSetBtn.href;
        }

        init() {
            this.listSelectorInputs.forEach((input) => {
                input.addEventListener('change', () => {
                    setTimeout(() => {
                        const selectedIds = this.selectedIds;
                        this.handleBtnsDisabling(selectedIds);
                        this.updateBtnsHref(selectedIds);
                    }, 300);
                });
            });
        }

        handleBtnsDisabling(ids) {
            const disabled = !ids.length;
            this.deleteSelectedRideSetBtn.classList.toggle('disabled', !!disabled);
        }

        updateBtnsHref(ids) {
            const requestUrl = new URL(this.deleteSelectedRideSetBtnUrl);
            if (ids.length > 0) {
                ids.map((id) => requestUrl.searchParams.append('ride_set_ids[]', id));
            }
            this.deleteSelectedRideSetBtn.setAttribute('href', requestUrl);
        }

        get selectedIds() {
            return [...this.listSelectorInputs]
                .filter((input) => input.checked && input.dataset.listSelector != 'all')
                .map((input) => input.dataset.listSelector);
        }
    }

    E.onDomReady(function () {
        const element = document.querySelector('#ride_sets-list');
        if (element !== null) {
            new RideSetGroups(element).init();
        }
    });
})(ekylibre);