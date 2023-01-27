(function (E) {
    class CropGroupList {
        constructor(element) {
            this.list = element;
            this.listSelectorInputs = element.querySelectorAll('input[data-list-selector]');
            this.interventionRequestBtn = element.parentElement.querySelector('#new-intervention-request-crop-groups');
            this.interventionRecordBtn = element.parentElement.querySelector('#new-intervention-record-crop-groups');
            this.interventionRequestUrl = this.interventionRequestBtn.href;
            this.interventionRecordUrl = this.interventionRecordBtn.href;
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
            this.interventionRequestBtn.classList.toggle('disabled', !!disabled);
            this.interventionRecordBtn.classList.toggle('disabled', !!disabled);
        }

        updateBtnsHref(ids) {
            const url_request = new URL(this.interventionRequestUrl);
            const url_record = new URL(this.interventionRecordUrl);
            if (ids.length > 0) {
                ids.map((id) => url_request.searchParams.append('crop_group_ids[]', id));
                ids.map((id) => url_record.searchParams.append('crop_group_ids[]', id));
            }
            this.interventionRequestBtn.setAttribute('href', url_request);
            this.interventionRecordBtn.setAttribute('href', url_record);
        }

        get selectedIds() {
            return [...this.listSelectorInputs]
                .filter((input) => input.checked && input.dataset.listSelector != 'all')
                .map((input) => input.dataset.listSelector);
        }
    }

    E.onDomReady(function () {
        const element = document.querySelector('#crop_groups-list');
        if (element !== null) {
            new CropGroupList(element).init();
        }
    });
})(ekylibre);
