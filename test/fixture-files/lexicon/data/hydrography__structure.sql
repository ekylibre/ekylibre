DROP TABLE IF EXISTS registered_hydrographic_items;

        CREATE TABLE registered_hydrographic_items (
          id character varying PRIMARY KEY NOT NULL,
          name jsonb,
          nature character varying,
          point postgis.geometry(Point,4326),
          shape postgis.geometry(MultiPolygonZM,4326),
          lines postgis.geometry(MultiLineStringZM,4326)
        );

        CREATE INDEX registered_hydrographic_items_nature ON registered_hydrographic_items(nature);
        CREATE INDEX registered_hydrographic_items_shape ON registered_hydrographic_items USING GIST (shape);
        CREATE INDEX registered_hydrographic_items_point ON registered_hydrographic_items USING GIST (point);
        CREATE INDEX registered_hydrographic_items_lines ON registered_hydrographic_items USING GIST (lines);
