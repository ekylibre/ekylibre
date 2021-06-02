import axios from 'axios';

interface Variety {
    label: string;
    referenceName: string;
}
export class VarietyService {
    selection(specie: string): Promise<Array<Variety>> {
        return axios.get(`/backend/varieties/selection.json?specie=${specie}`).then((res) => res.data);
    }
}
