DROP TABLE IF EXISTS registered_hydrographic_items;
DROP TABLE IF EXISTS registered_area_items;
DROP TABLE IF EXISTS registered_cadastral_buildings;

         CREATE TABLE registered_cadastral_buildings(
          id SERIAL PRIMARY KEY NOT NULL,
          reference_name character varying,
          nature character varying,
          shape postgis.geometry(MultiPolygon, 4326) NOT NULL,
          centroid postgis.geometry(Point, 4326)
        );
        CREATE INDEX registered_cadastral_buildings_id ON registered_cadastral_buildings(id);
        CREATE INDEX registered_cadastral_buildings_reference_name ON registered_cadastral_buildings(reference_name);
        CREATE INDEX registered_cadastral_buildings_shape ON registered_cadastral_buildings USING GIST (shape);
        CREATE INDEX registered_cadastral_buildings_centroid ON registered_cadastral_buildings USING GIST (centroid);

        CREATE TABLE registered_area_items (
          id character varying PRIMARY KEY NOT NULL,
          name jsonb,
          nature character varying,
          point postgis.geometry(Point,4326),
          shape postgis.geometry(MultiPolygon,4326),
          lines postgis.geometry(MultiLineString,4326),
          centroid postgis.geometry(Point, 4326)
        );
        CREATE INDEX registered_area_items_id ON registered_area_items(id);
        CREATE INDEX registered_area_items_nature ON registered_area_items(nature);
        CREATE INDEX registered_area_items_shape ON registered_area_items USING GIST (shape);
        CREATE INDEX registered_area_items_point ON registered_area_items USING GIST (point);
        CREATE INDEX registered_area_items_lines ON registered_area_items USING GIST (lines);
        CREATE INDEX registered_area_items_centroid ON registered_area_items USING GIST (centroid);

         CREATE TABLE registered_hydrographic_items (
           id character varying PRIMARY KEY NOT NULL, 
           name jsonb,
           nature character varying,
           point postgis.geometry(Point,4326),
           shape postgis.geometry(MultiPolygon,4326),
           lines postgis.geometry(MultiLineString,4326),
           centroid postgis.geometry(Point, 4326)
        );
        CREATE INDEX registered_hydrographic_items_nature ON registered_hydrographic_items(nature);
        CREATE INDEX registered_hydrographic_items_shape ON registered_hydrographic_items USING GIST (shape);
        CREATE INDEX registered_hydrographic_items_point ON registered_hydrographic_items USING GIST (point);
        CREATE INDEX registered_hydrographic_items_lines ON registered_hydrographic_items USING GIST (lines);
        CREATE INDEX registered_hydrographic_items_centroid ON registered_hydrographic_items USING GIST (centroid);
