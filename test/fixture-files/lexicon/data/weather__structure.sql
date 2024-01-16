DROP TABLE IF EXISTS registered_hourly_weathers;
DROP TABLE IF EXISTS registered_weather_stations;

        CREATE TABLE registered_weather_stations (
          reference_name character varying PRIMARY KEY NOT NULL,
          country character varying NOT NULL,
          country_zone character varying NOT NULL,
          station_code character varying NOT NULL,
          station_name character varying NOT NULL,
          elevation integer,
          centroid postgis.geometry(Point,4326)
        );
        
          CREATE INDEX registered_weather_stations_country ON registered_weather_stations(country);
          CREATE INDEX registered_weather_stations_country_zone ON registered_weather_stations(country_zone);
          CREATE INDEX registered_weather_stations_reference_name ON registered_weather_stations(reference_name);
          CREATE INDEX registered_weather_stations_centroid ON registered_weather_stations USING GIST (centroid);

        CREATE TABLE registered_hourly_weathers (
          station_id character varying,
          started_at timestamp,
          mesured_delay interval,
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
        
          CREATE INDEX registered_hourly_weathers_rain ON registered_hourly_weathers(rain);
          CREATE INDEX registered_hourly_weathers_station_id ON registered_hourly_weathers(station_id);
          CREATE INDEX registered_hourly_weathers_started_at ON registered_hourly_weathers(started_at);
          CREATE INDEX registered_hourly_weathers_average_temp ON registered_hourly_weathers(average_temp);
          CREATE INDEX registered_hourly_weathers_max_wind_speed ON registered_hourly_weathers(max_wind_speed);
          CREATE INDEX registered_hourly_weathers_pressure ON registered_hourly_weathers(pressure);
