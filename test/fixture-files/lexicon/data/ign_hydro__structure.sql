DROP TABLE IF EXISTS registered_hydro_items;

        CREATE UNLOGGED TABLE registered_hydro_items (
          id character varying PRIMARY KEY NOT NULL,
          name jsonb,
          nature character varying,
          point postgis.geometry(Point,4326),
          shape postgis.geometry(MultiPolygonZM,4326),
          lines postgis.geometry(MultiLineStringZM,4326)
        );

        CREATE INDEX registered_hydro_items_nature ON registered_hydro_items(nature);
        CREATE INDEX registered_hydro_items_shape ON registered_hydro_items USING GIST (shape);
        CREATE INDEX registered_hydro_items_point ON registered_hydro_items USING GIST (point);
        CREATE INDEX registered_hydro_items_lines ON registered_hydro_items USING GIST (lines);
