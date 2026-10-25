DROP TABLE IF EXISTS registered_cadastral_parcel_owners;
DROP TABLE IF EXISTS registered_cadastral_premises;
DROP TABLE IF EXISTS registered_cadastral_owners;

        CREATE TABLE registered_cadastral_owners (
          majic_number       character varying NOT NULL,
          department_code    character varying NOT NULL,
          siren              character varying,
          denomination       character varying,
          legal_form_code    character varying,
          legal_form_short   character varying,
          person_group_code  character varying,
          person_group_label character varying,
          PRIMARY KEY (majic_number, department_code)
        );
        CREATE INDEX registered_cadastral_owners_majic ON registered_cadastral_owners(majic_number);
        CREATE INDEX registered_cadastral_owners_department ON registered_cadastral_owners(department_code);
        CREATE INDEX registered_cadastral_owners_siren ON registered_cadastral_owners(siren);
        CREATE INDEX registered_cadastral_owners_denomination ON registered_cadastral_owners(denomination);
        CREATE INDEX registered_cadastral_owners_person_group ON registered_cadastral_owners(person_group_code);

        CREATE TABLE registered_cadastral_premises (
          id                    serial PRIMARY KEY NOT NULL,
          cadastral_parcel_id   character varying NOT NULL,
          town_insee_code       character varying NOT NULL,
          department_code       character varying NOT NULL,
          section_prefix        character varying,
          section               character varying,
          work_number           character varying,
          building              character varying,
          entrance              character varying,
          level                 character varying,
          door                  character varying,
          address               character varying,
          street_rivoli_code    character varying,
          droit_code            character varying,
          majic_number          character varying NOT NULL,
          siren                 character varying
        );
        CREATE INDEX registered_cadastral_premises_parcel_id ON registered_cadastral_premises(cadastral_parcel_id);
        CREATE INDEX registered_cadastral_premises_majic ON registered_cadastral_premises(majic_number);
        CREATE INDEX registered_cadastral_premises_majic_dept ON registered_cadastral_premises(majic_number, department_code);
        CREATE INDEX registered_cadastral_premises_siren ON registered_cadastral_premises(siren);
        CREATE INDEX registered_cadastral_premises_insee ON registered_cadastral_premises(town_insee_code);
        CREATE INDEX registered_cadastral_premises_department ON registered_cadastral_premises(department_code);

        CREATE TABLE registered_cadastral_parcel_owners (
          id                       serial PRIMARY KEY NOT NULL,
          cadastral_parcel_id      character varying NOT NULL,
          town_insee_code          character varying NOT NULL,
          department_code          character varying NOT NULL,
          section_prefix           character varying,
          section                  character varying,
          work_number              character varying,
          parcel_surface_area      integer,
          suf                      character varying,
          culture_nature_code      character varying,
          suf_surface_area         integer,
          address                  character varying,
          street_rivoli_code       character varying,
          droit_code               character varying,
          majic_number             character varying NOT NULL,
          siren                    character varying
        );
        CREATE INDEX registered_cadastral_parcel_owners_parcel_id   ON registered_cadastral_parcel_owners(cadastral_parcel_id);
        CREATE INDEX registered_cadastral_parcel_owners_majic       ON registered_cadastral_parcel_owners(majic_number);
        CREATE INDEX registered_cadastral_parcel_owners_majic_dept  ON registered_cadastral_parcel_owners(majic_number, department_code);
        CREATE INDEX registered_cadastral_parcel_owners_siren       ON registered_cadastral_parcel_owners(siren);
        CREATE INDEX registered_cadastral_parcel_owners_insee       ON registered_cadastral_parcel_owners(town_insee_code);
        CREATE INDEX registered_cadastral_parcel_owners_department  ON registered_cadastral_parcel_owners(department_code);
        CREATE INDEX registered_cadastral_parcel_owners_culture     ON registered_cadastral_parcel_owners(culture_nature_code);
