import axios from 'axios';

interface CultivableZone {
    name: string;
    shape: unknown;
}

export class CultivableZoneService {
    get(id: number): Promise<CultivableZone> {
        return axios.get<CultivableZone>(`/backend/cultivable-zones/${id}.json`).then((res) => res.data);
    }
}
