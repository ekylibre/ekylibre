(function (E) {
    function activateFlatpickr() {
        const reconciliationList = document.getElementById('reconciliation-list');
        if (!reconciliationList) { return }

        function handleSelectedDate(date) {
            E.bankReconciliation.createBankStatementItem(date);
            return false;
        }

        const button = document.querySelector('button#new-line');
        const ranges = JSON.parse(button.dataset.bankStatementDatesRanges);
        const fp = flatpickr(button, {
            enable: ranges.map(e => ({from: e.start, to: e.end})),
            locale: I18n.locale.slice(0, 2),
            defaultDate: moment.min(ranges.map(e => moment(e.start))).toDate(),
            onChange: function (selectedDates, dateStr, instance) {
                handleSelectedDate(selectedDates[0])
            },
            clickOpens: false
        });
        button.onmousedown = function () {
            fp.open()
        };
    }

    document.addEventListener('page:load', activateFlatpickr);
    document.addEventListener('DOMContentLoaded', activateFlatpickr);

})(ekylibre);
