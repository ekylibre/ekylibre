import axios from 'axios';

const getCountryISO3 = require('country-iso-2-to-3');

class HereGeocoder {
    constructor(options) {
        this.apiKey = options.apiKey;
    }

    async suggest(address, country) {
        const action = 'geocode';
        try {
            const response = await axios.get(this.url(action, address, country));
            return response.data.items;
        } catch (err) {
            console.error(err);
        }
    }

    async geocode(address) {
        const action = 'geocode';
        try {
            const response = await axios.get(this.url(action, address));
            return response.data.items;
        } catch (err) {
            console.error(err);
        }
    }

    url(action, address, country) {
        const url = new URL(`https://autocomplete.search.hereapi.com/v1/${action}`);
        url.searchParams.append('apiKey', this.apiKey);
        url.searchParams.append('q', address);
        if (country) {
            url.searchParams.append('in', `countryCode:${getCountryISO3(country.toUpperCase())}`);
        }
        return url;
    }
}

export class GeocodingService {
    constructor() {
        const hereApiKey = process.env.HERE_API_KEY;
        this.hereGeocoder = new HereGeocoder({ apiKey: hereApiKey });
    }

    suggest(address, country) {
        return this.hereGeocoder.suggest(address, country).then((suggestions) => suggestions.map((suggestion) => suggestion.address.label));
    }

    geocode(address) {
        return this.hereGeocoder.geocode(address).then((suggestions) => suggestions.map((suggestion) => suggestion.position)[0]);
    }
}
