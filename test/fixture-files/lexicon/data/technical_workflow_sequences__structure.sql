DROP TABLE IF EXISTS technical_workflow_sequences;

        CREATE UNLOGGED TABLE technical_workflow_sequences (
          id character varying PRIMARY KEY NOT NULL,
          technical_workflow_sequence_id character varying NOT NULL,
          name jsonb NOT NULL,
          family character varying,
          specie character varying,
          production_system character varying,
          year_start integer,
          year_stop integer,
          technical_workflow_id character varying NOT NULL
        );

        CREATE INDEX technical_workflow_sequences_technical_workflow_sequence_id ON technical_workflow_sequences(technical_workflow_sequence_id);
        CREATE INDEX technical_workflow_sequences_family ON technical_workflow_sequences(family);
        CREATE INDEX technical_workflow_sequences_specie ON technical_workflow_sequences(specie);
        CREATE INDEX technical_workflow_sequences_technical_workflow_id ON technical_workflow_sequences(technical_workflow_id);
