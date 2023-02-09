import axios from 'axios';

interface Unit {
    id: number;
    reference_name: string;
    dimension: string;
}

export class UnitService {
    get(id: number): Promise<Unit> {
        return axios.get(`/backend/units/${id}.json`).then((res) => res.data);
    }
}
