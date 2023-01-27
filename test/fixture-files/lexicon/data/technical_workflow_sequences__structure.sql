DROP TABLE IF EXISTS technical_workflow_sequences;
DROP TABLE IF EXISTS technical_sequences;

        CREATE TABLE technical_sequences (
          id character varying PRIMARY KEY NOT NULL,
          family character varying,
          production_reference_name character varying NOT NULL,
          production_system character varying,
          translation_id character varying NOT NULL
        );

        CREATE INDEX technical_sequences_id ON technical_sequences(id);
        CREATE INDEX technical_sequences_family ON technical_sequences(family);
        CREATE INDEX technical_sequences_production_reference_name ON technical_sequences(production_reference_name);

        CREATE TABLE technical_workflow_sequences (
          technical_sequence_id character varying NOT NULL,
          year_start integer,
          year_stop integer,
          technical_workflow_id character varying NOT NULL
        );

        CREATE INDEX technical_workflow_sequences_technical_sequence_id ON technical_workflow_sequences(technical_sequence_id);
        CREATE INDEX technical_workflow_sequences_technical_workflow_id ON technical_workflow_sequences(technical_workflow_id);
