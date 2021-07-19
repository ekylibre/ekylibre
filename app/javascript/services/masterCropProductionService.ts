import axios from 'axios';

interface MasterCropProduction {
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

export class MasterCropProductionService {
    get(reference_name: string): Promise<MasterCropProduction> {
        return axios.get<MasterCropProduction>(`/backend/master_crop_productions/${reference_name}.json`).then((res) => res.data);
    }
}
