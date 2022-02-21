(function (E, cable) {
    if (!cable.subscriptions.PerformJobButtonsChannel) {
        cable.consumer.subscriptions.create('PerformJobButtonsChannel', {
            received: function (data) {
                switch (data.status) {
                    case 'enqueued':
                        const button = document.querySelector(`[data-perform-job-button][data-job='${data.job}']`);
                        if (!!button) {
                            button.setAttribute('disabled', true);
                            button.querySelector('span.spinner').classList.add('active');
                        }
                        break;
                    case 'over':
                        const buttonDisabled = document.querySelector(`[data-perform-job-button][data-job='${data.job}']`);
                        if (!!buttonDisabled) {
                            Turbolinks.visit(window.location);
                            buttonDisabled.removeAttribute('disabled');
                            buttonDisabled.querySelector('span.spinner').classList.remove('active');
                        }
                        break;
                }
            },
            connected: function () {
                cable.subscriptions.PerformJobButtonsChannel = this;
            },
        });
    }
})(ekylibre, cable);
