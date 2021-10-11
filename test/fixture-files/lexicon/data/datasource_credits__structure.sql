DROP TABLE IF EXISTS datasource_credits;

          CREATE TABLE IF NOT EXISTS datasource_credits (
            "datasource" VARCHAR,
            "name" VARCHAR,
            "url" VARCHAR,
            "provider" VARCHAR,
            "licence" VARCHAR,
            "licence_url" VARCHAR,
            "updated_at" TIMESTAMP WITH TIME ZONE
          );
