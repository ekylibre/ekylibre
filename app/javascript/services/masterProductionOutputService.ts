import axios from 'axios';

interface MasterProductionOutput {
    production_nature_id: number;
    production_system_name: string;
    name: string;
    average_yield: number;
    main: boolean;
    analysis_items: string;
}

export class MasterProductionOutputService {
    getAll(params: Record<string, string>): Promise<MasterProductionOutput> {
        return axios
            .get<MasterProductionOutput>('/backend/master_production_outputs', {
                params: params,
                headers: { Accept: 'application/json' },
            })
            .then((res) => res.data);
    }
}
