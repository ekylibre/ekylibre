DROP TABLE IF EXISTS registered_hourly_weathers;

        CREATE TABLE registered_hourly_weathers (
          country character varying NOT NULL,
          country_zone character varying NOT NULL,
          station_code character varying NOT NULL,
          station_name character varying NOT NULL,
          elevation integer,
          started_at timestamp,
          mesured_delay interval,
          centroid postgis.geometry(Point,4326),
          average_temp numeric(19,4),
          min_temp numeric(19,4),
          max_temp numeric(19,4),
          rain numeric(19,4),
          max_wind_speed numeric(19,4),
          wind_direction numeric(19,4),
          frozen_duration numeric(19,4),
          humidity numeric(19,4),
          soil_state character varying,
          pressure numeric(19,4),
          weather_description character varying
      );

        CREATE INDEX registered_hourly_weathers_country ON registered_hourly_weathers(country);
        CREATE INDEX registered_hourly_weathers_country_zone ON registered_hourly_weathers(country_zone);
        CREATE INDEX registered_hourly_weathers_mesured_delay ON registered_hourly_weathers(mesured_delay);
        CREATE INDEX registered_hourly_weathers_centroid ON registered_hourly_weathers USING GIST (centroid);
