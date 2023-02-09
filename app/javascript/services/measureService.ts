import axios from 'axios';

interface Measure {
    value: number;
    unit: string;
}

export class MeasureService {
    convert(value: number, from: string, to: string): Promise<Measure> {
        return axios
            .get('/backend/measures/convert', {
                params: {
                    value,
                    from,
                    to,
                },
            })
            .then((res) => res.data);
    }
}
