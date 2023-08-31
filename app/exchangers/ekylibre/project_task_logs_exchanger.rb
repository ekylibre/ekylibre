# frozen_string_literal: true

module Ekylibre
  class ProjectTaskLogsExchanger < ActiveExchanger::Base
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

      s.sheets.each do |sheet_name|
        next unless sheet_name.to_s == 'temps'

        s.sheet(sheet_name)

        # 1 first line are not budget items
        2.upto(s.last_row) do |row_number|
          next if s.cell('A', row_number).blank?

          r = {
            started_on: (s.cell('A', row_number).blank? ? nil : Date.parse(s.cell('A', row_number).to_s)),
            duration: (s.cell('B', row_number).blank? ? nil : s.cell('B', row_number).to_s.tr(',', '.').to_d),
            project_task_work_number: (s.cell('C', row_number).blank? ? nil : s.cell('C', row_number).to_s.strip.upcase),
            description: (s.cell('D', row_number).blank? ? nil : s.cell('D', row_number).to_s),
            worker_code: (s.cell('E', row_number).blank? ? nil : s.cell('E', row_number).to_s),
            travel_expense_details: (s.cell('F', row_number).blank? ? nil : s.cell('F', row_number).to_s)
          }.to_struct

          w.info "----------------------#{row_number}----------------------".inspect.yellow

          unless r.duration
            w.error 'Missing duration'
          end

          unless r.project_task_work_number
            w.error 'Missing project task number'
          end

          # get the task from the code
          project_task = ProjectTask.find_by(work_number: r.project_task_work_number) if r.project_task_work_number

          unless project_task
            w.error "Cannot find project task with #{r.project_task_work_number}"
          end

          unless r.started_on
            w.error 'Missing started_on'
          end

          unless r.worker_code
            w.error 'Missing worker_code'
          end

          # get the entity and the user
          worker = Worker.find_by(work_number: r.worker_code) if r.worker_code

          unless worker
            w.error "Cannot find user with #{r.worker_code}"
          end

          w.info "worker : #{worker.name} | project_task : #{project_task.work_number}".inspect.yellow

          # find or create task log
          next unless worker && project_task && r.started_on && r.duration

          started_at = r.started_on.beginning_of_day + 8.hours

          p = WorkerTimeLog.where(project_task_id: project_task.id, started_at: started_at, duration: (r.duration * 3600).to_i, worker_id: worker.id, description: r.description).first

          if p
            w.info "Log already exist : #{p.id}".inspect.red if p
          else
            p = WorkerTimeLog.create!(started_at: started_at,
                                     project_task_id: project_task.id,
                                     duration: (r.duration * 3600).to_i,
                                     description: r.description,
                                     worker_id: worker.id,
                                     travel_expense: !r.travel_expense_details.nil?,
                                     travel_expense_details: (r.travel_expense_details.nil? ? nil : r.travel_expense_details),)
            w.info "Log created : #{p.id}".inspect.yellow if p
          end
        end
      end
    end

  end
end
