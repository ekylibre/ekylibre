DROP TABLE IF EXISTS registered_soil_available_water_capacities;
DROP TABLE IF EXISTS registered_soil_depths;

        CREATE TABLE registered_soil_depths (
          id character varying PRIMARY KEY NOT NULL,
          soil_depth_value numeric(19,4),
          soil_depth_unit character varying,
          shape postgis.geometry(MultiPolygon, 4326) NOT NULL
        );
        CREATE INDEX registered_soil_depths_id ON registered_soil_depths (id);
        CREATE INDEX registered_soil_depths_shape ON registered_soil_depths USING GIST (shape);

        CREATE TABLE registered_soil_available_water_capacities (
          id character varying PRIMARY KEY NOT NULL,
          available_water_reference_value integer,
          available_water_min_value numeric(19,4),
          available_water_max_value numeric(19,4),
          available_water_unit character varying,
          available_water_label character varying,
          shape postgis.geometry(MultiPolygon, 4326) NOT NULL
        );
        CREATE INDEX registered_soil_available_water_capacities_id ON registered_soil_available_water_capacities (id);
        CREATE INDEX registered_soil_available_water_capacities_shape ON registered_soil_available_water_capacities USING GIST (shape);
