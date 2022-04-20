import axios from 'axios';

interface Product {
    born_at: string;
    category_id: number;
    conditioning_coefficient: string;
    conditioning_unit_name: string;
    id: number;
    identification_number: string;
    name: string;
    nature_id: number;
    number: string;
    ownership: Owner;
    population: string;
    population_counting: string;
    unit_name: string;
    variant: Variant;
    work_number: string;
    readings: Array<Reading>;
}

interface Reading {
    id: number;
    indicator_name: string;
    indicator_datatype: string;
    absolute_measure_value_value: string;
    absolute_measure_value_unit: string;
    boolean_value: boolean;
    choice_value: string;
    decimal_value: string;
    multi_polygon_value: string;
    integer_value: number;
    measure_value_value: string;
    measure_value_unit: string;
    point_value: string;
    string_value: string;
}

interface Owner {
    nature: string;
    owner_id: number;
}

interface Variant {
    id: number;
    name: string;
}

export class ProductService {
    get(id: number): Promise<Product> {
        return axios.get(`/backend/products/${id}.json`).then((res) => res.data);
    }
}
