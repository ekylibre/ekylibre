import axios, {AxiosRequestConfig, AxiosResponse} from 'axios';
import {Modal, openRemote} from "components/modal";

interface DialogOptions {
    success?: (response: AxiosResponse) => any
    invalid?: (response: AxiosResponse) => any
    error?: (response: AxiosResponse) => any
}

function handleTitle(modal: Modal) {
    const h1 = modal.getBodyElement().querySelector('h1');
    if (h1 !== null) {
        modal.setTitle(h1.textContent || '');
        h1.remove();
    }
}

const requestConfigDefaults = {
    headers: {
        'X-Requested-With': 'XMLHTTPRequest'
    }
};

export async function openDialog(url: string, options: DialogOptions): Promise<Modal> {
    let {modal} = await openRemote(url, {size: 'lg', requestConfig: {...requestConfigDefaults, params: {dialog: '1'}});
    handleTitle(modal);

    modal.on('submit', 'form', e => {
        e.preventDefault();

        const form = e.target as HTMLFormElement;

        const data = new FormData(form);
        data.set('dialog', '1');

        axios.post(form.action, data, requestConfigDefaults)
            .then(response => {
                const statusCode = response.headers['x-return-code'];

                if (statusCode && statusCode == 'invalid') {
                    options.invalid && options.invalid(response);
                    modal.setBodyString(response.data);
                    handleTitle(modal);
                } else {
                    options.success && options.success(response);
                    modal.close();
                }
            })
            .catch(({response}) => {
                options.error && options.error(response);
            });
    });

    modal.on('click', '.form-actions a.btn', (e) => {
        e.preventDefault();

        modal.close();
    });

    return this;
}