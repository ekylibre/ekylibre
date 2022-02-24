import axios from 'axios';

interface Campaign {
    id: number;
    name: string;
}

export class CampaignService {
    getByName(name: string): Promise<Campaign> {
        return axios.get<Campaign>(`/backend/campaigns/show_by_name.json?name=${name}`).then((res) => res.data);
    }
}
