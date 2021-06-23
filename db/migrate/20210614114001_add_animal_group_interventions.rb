class AddAnimalGroupInterventions < ActiveRecord::Migration[5.0]
  def change
    # having a view to get animal and group on interventions
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE OR REPLACE VIEW animals_interventions AS
          SELECT
            'animal_group' as initial_target,
            intervention.id as intervention_id,
            animal_group.id as animal_group_id,
            animal.id as animal_id
          FROM interventions as intervention
          JOIN intervention_parameters as target ON target.intervention_id = intervention.id AND target.type = 'InterventionTarget'
          JOIN products as animal_group ON animal_group.id = target.product_id AND animal_group.type = 'AnimalGroup'
          JOIN product_memberships as pm ON pm.group_id = animal_group.id
            AND (
            (intervention.started_at BETWEEN pm.started_at AND pm.stopped_at) OR (intervention.started_at > pm.started_at AND pm.stopped_at IS NULL)
            OR (intervention.stopped_at BETWEEN pm.started_at AND pm.stopped_at) OR (intervention.stopped_at > pm.started_at AND pm.stopped_at IS NULL)
            )
          JOIN products as animal ON pm.member_id = animal.id AND animal.type = 'Animal'
          GROUP BY intervention.id, animal.id, animal_group.id, pm.group_id
          UNION ALL
          SELECT
            'animal' as initial_target,
            intervention.id as intervention_id,
            animal_group.id as animal_group_id,
            animal.id as animal_id
          FROM interventions as intervention
          JOIN intervention_parameters as target ON target.intervention_id = intervention.id AND target.type = 'InterventionTarget'
          JOIN products as animal ON animal.id = target.product_id AND animal.type = 'Animal'
          JOIN product_memberships as pm ON pm.member_id = animal.id
            AND (
            (intervention.started_at BETWEEN pm.started_at AND pm.stopped_at) OR (intervention.started_at > pm.started_at AND pm.stopped_at IS NULL)
            OR (intervention.stopped_at BETWEEN pm.started_at AND pm.stopped_at) OR (intervention.stopped_at > pm.started_at AND pm.stopped_at IS NULL)
            )
          JOIN products as animal_group ON pm.group_id = animal_group.id AND animal_group.type = 'AnimalGroup'
          GROUP BY intervention.id, animal.id, animal_group.id, pm.group_id;
        SQL
      end

      dir.down do

        execute <<~SQL
          DROP VIEW IF EXISTS animals_interventions;
        SQL

      end
    end
  end
end
