import { onElementDetected } from 'lib/domEventUtils';
import axios from 'axios';
import { Modal } from 'components/modal';
import { translate as t } from 'services/i18n';

onElementDetected('generate-land-parcel-btn', (element) => {
    element.addEventListener('click', async (_e) => {
        const params: any = {};
        const zone = element.dataset.cultivableZone;
        if (zone) {
            params['cultivable_zone'] = zone;
        }

        const response = await axios.get('/backend/controller_helpers/activity_production_creations/new', { params });
        const title = t('front-end.land_parcel.create_modal.title');
        const modal = new Modal(title, response.data, { size: 'lg' });

        modal.open();

        modal.on('submit', 'form', (e) => {
            const form = e.target as HTMLFormElement;
            e.preventDefault();

            const data = new FormData(form);

            axios
                .post(form.action, data)
                .then((response) => {
                    if (response.headers.location) {
                        window.location.href = response.headers.location;
                    } else {
                        modal.getBodyElement().prepend('An error occured');
                    }
                })
                .catch(({ response }) => {
                    if (response.status === 400) {
                        modal.setBodyString(response.data);
                    }
                });
        });
    });
});
