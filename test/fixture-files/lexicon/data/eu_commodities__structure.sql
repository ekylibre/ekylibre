DROP TABLE IF EXISTS eu_market_prices;

        CREATE UNLOGGED TABLE eu_market_prices (
          id character varying PRIMARY KEY NOT NULL,
          category character varying,
          sector_code character varying,
          product_code character varying,
          product_label character varying,
          product_description character varying,
          unit_value integer,
          unit_name character varying,
          country character varying,
          price numeric(8,2),
          start_date date
        );

        CREATE INDEX eu_market_prices_id ON eu_market_prices(id);
        CREATE INDEX eu_market_prices_category ON eu_market_prices(category);
        CREATE INDEX eu_market_prices_sector_code ON eu_market_prices(sector_code);
        CREATE INDEX eu_market_prices_product_code ON eu_market_prices(product_code);
