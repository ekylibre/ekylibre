import axios from 'axios';

interface MasterProduction {
    specie: string;
    started_on: string;
    stopped_on: string;
    start_state_of_production: Array<StartStateOfProduction>;
    cycle: string;
    started_on_year: number;
    stopped_on_year: number;
    life_duration: number;
}

interface StartStateOfProduction {
    label: string;
    year: number;
    default: boolean;
}

export class MasterProductionService {
    get(reference_name: string): Promise<MasterProduction> {
        return axios.get<MasterProduction>(`/backend/master_productions/${reference_name}.json`).then((res) => res.data);
    }
}
