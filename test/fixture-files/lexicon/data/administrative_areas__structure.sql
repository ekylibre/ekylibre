DROP TABLE IF EXISTS registered_administrative_areas;

        CREATE TABLE registered_administrative_areas (
          kind         character varying NOT NULL,
          code         character varying NOT NULL,
          name         character varying NOT NULL,
          parent_code  character varying,
          shape        postgis.geometry(MultiPolygon, 4326) NOT NULL,
          centroid     postgis.geometry(Point, 4326),
          PRIMARY KEY (kind, code),
          CONSTRAINT registered_administrative_areas_kind_chk
            CHECK (kind IN ('region', 'department'))
        );
        CREATE INDEX registered_administrative_areas_code        ON registered_administrative_areas(code);
        CREATE INDEX registered_administrative_areas_parent_code ON registered_administrative_areas(parent_code);
        CREATE INDEX registered_administrative_areas_shape       ON registered_administrative_areas USING GIST (shape);
        CREATE INDEX registered_administrative_areas_centroid    ON registered_administrative_areas USING GIST (centroid);
