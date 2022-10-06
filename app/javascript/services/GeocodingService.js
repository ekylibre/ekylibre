import axios from 'axios';

class HereGeocoder {
    constructor(options) {
        this.apiKey = options.apiKey;
    }

    async suggest(address) {
        const action = 'autocomplete';
        try {
            const response = await axios.get(this.url(action, address));
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

    url(action, address) {
        const url = new URL(`https://autocomplete.search.hereapi.com/v1/${action}`);
        url.searchParams.append('apiKey', this.apiKey);
        url.searchParams.append('q', address);
        return url;
    }
}

export class GeocodingService {
    constructor() {
        const hereApiKey = process.env.HERE_API_KEY;
        this.hereGeocoder = new HereGeocoder({ apiKey: hereApiKey });
    }

    suggest(address) {
        return this.hereGeocoder.suggest(address).then((suggestions) => suggestions.map((suggestion) => suggestion.address.label));
    }

    geocode(address) {
        return this.hereGeocoder.geocode(address).then((suggestions) => suggestions.map((suggestion) => suggestion.position)[0]);
    }
}
