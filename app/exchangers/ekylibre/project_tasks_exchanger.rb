# frozen_string_literal: true

module Ekylibre
  class ProjectTasksExchanger < ActiveExchanger::Base
    category :human_resources
    vendor :ekylibre
    def import
      s = Roo::OpenOffice.new(file)
      w.count = s.sheets.count

      # file format
      # A Date de début
      # B Durée en heure
      # C Code de la tâches (work_number)
      # D Description
      # E Code de la personne
      # F Note de frais
      # G Tiers (number ou siret_number ou full_name)

      s.sheets.each do |sheet_name|
        next unless sheet_name.to_s == 'taches'

        s.sheet(sheet_name)

        # 1 first line are not budget items
        2.upto(s.last_row) do |row_number|
          next if s.cell('A', row_number).blank?

          r = {
            team: (s.cell('A', row_number).blank? ? nil : s.cell('A', row_number).to_s),
            project_name: (s.cell('B', row_number).blank? ? nil : s.cell('B', row_number).to_s),
            project_work_number: (s.cell('C', row_number).blank? ? nil : s.cell('C', row_number).to_s),
            project_task_name: (s.cell('D', row_number).blank? ? nil : s.cell('D', row_number).to_s),
            project_task_work_number: (s.cell('E', row_number).blank? ? nil : s.cell('E', row_number).to_s)
          }.to_struct

          # get the team or create it
          if r.team
            t = Team.find_by(name: r.team.delete(' ').strip)
            t ||= Team.create!(name: r.team.delete(' ').strip)
          else
            w.error 'You must give team name'
          end

          # get the project from the code or create it
          if r.project_work_number && t
            project = Project.find_by(work_number: r.project_work_number)
            project ||= Project.create!(name: r.project_name, work_number: r.project_work_number, team_id: t.id, nature: :indirect_earning)
          else
            w.error 'You must give project work number'
          end

          # get the project task from the code or create it
          if r.project_task_work_number && project
            project_task = ProjectTask.find_by(work_number: r.project_task_work_number)
            project_task ||= ProjectTask.create!(project_id: project.id, name: r.project_task_name, work_number: r.project_task_work_number)
          else
            w.error 'You must give project_task work number'
          end
        end
      end
    end
  end
end
