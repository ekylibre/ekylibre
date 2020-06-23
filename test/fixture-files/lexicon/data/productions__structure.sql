DROP TABLE IF EXISTS master_production_outputs;
DROP TABLE IF EXISTS master_production_natures;

        CREATE UNLOGGED TABLE master_production_natures (
          id integer PRIMARY KEY NOT NULL,
          specie character varying NOT NULL,
          human_name JSONB,
          human_name_fra character varying NOT NULL,
          started_on DATE NOT NULL,
          stopped_on DATE NOT NULL,
          agroedi_crop_code character varying,
          season character varying,
          pfi_crop_code character varying,
          cap_2017_crop_code character varying,
          cap_2018_crop_code character varying,
          cap_2019_crop_code character varying,
          cap_2020_crop_code character varying,
          start_state_of_production JSONB,
          life_duration numeric(5,2)
        );

        CREATE INDEX master_production_natures_specie ON master_production_natures(specie);
        CREATE INDEX master_production_natures_human_name ON master_production_natures(human_name);
        CREATE INDEX master_production_natures_human_name_fra ON master_production_natures(human_name_fra);
        CREATE INDEX master_production_natures_agroedi_crop_code ON master_production_natures(agroedi_crop_code);
        CREATE INDEX master_production_natures_pfi_crop_code ON master_production_natures(pfi_crop_code);
        CREATE INDEX master_production_natures_cap_2017_crop_code ON master_production_natures(cap_2017_crop_code);
        CREATE INDEX master_production_natures_cap_2018_crop_code ON master_production_natures(cap_2018_crop_code);
        CREATE INDEX master_production_natures_cap_2019_crop_code ON master_production_natures(cap_2019_crop_code);
        CREATE INDEX master_production_natures_cap_2020_crop_code ON master_production_natures(cap_2020_crop_code);

        CREATE UNLOGGED TABLE master_production_outputs (
          production_nature_id INTEGER NOT NULL,
          production_system_name VARCHAR NOT NULL,
          name VARCHAR NOT NULL,
          average_yield NUMERIC(19,4),
          main BOOLEAN NOT NULL DEFAULT FALSE,
          analysis_items VARCHAR[],
          PRIMARY KEY (production_nature_id, production_system_name, name)
        );

        CREATE INDEX master_production_outputs_nature_id ON master_production_outputs(production_nature_id);
        CREATE INDEX master_production_outputs_system_name ON master_production_outputs(production_system_name);
        CREATE INDEX master_production_outputs_name ON master_production_outputs(name);
