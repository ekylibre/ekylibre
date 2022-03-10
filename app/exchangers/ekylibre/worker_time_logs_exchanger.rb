# frozen_string_literal: true

module Ekylibre
  class WorkerTimeLogsExchanger < ActiveExchanger::Base
    category :human_resources
    vendor :ekylibre

    # encoding UTF-8, separator ;, headers: true
    NORMALIZATION_CONFIG = [
      { col: 0, name: :worker, type: :string, constraint: :not_nil },
      { col: 1, name: :started_on, type: :date, constraint: :not_nil },
      { col: 2, name: :hour_started_on, type: :string, constraint: :not_nil },
      { col: 3, name: :duration, type: :float, constraint: :greater_to_zero }
    ].freeze

    def check
      valid = true
      data, errors = open_and_decode_file(file)

      valid = errors.all?(&:empty?)
      if valid == false
        w.error "The file is invalid: #{errors}"
        return false
      end

      data.each_with_index do |time_log, index|
        if time_log.worker
          if Worker.find_by(id: time_log.worker.to_i)
            valid = true
          elsif Worker.find_by(work_number: time_log.worker)
            valid = true
          elsif Worker.where('name ILIKE ?', time_log.worker).any?
            valid = true
          else
            w.error "No worker found on line #{index + 1}"
            valid = false
          end
        else
          w.error "No worker present on line #{index + 1}"
          valid = false
        end
        if time_log.duration > 24.0
          w.error "Duration #{time_log.duration} on line #{index + 1} can't be > 24 or < 0"
          valid = false
        end
        if time_log.started_on > Date.today
          w.error "Start date #{time_log.started_on} on line #{index + 1} can't be > #{Date.today}"
          valid = false
        end
      end
      valid
    end

    def import
      data, _errors = open_and_decode_file(file)
      w.count = data.size
      data.each do |time_log|
        # find worker
        if Worker.find_by(id: time_log.worker.to_i)
          worker = Worker.find_by(id: time_log.worker.to_i)
        elsif Worker.find_by(work_number: time_log.worker)
          worker = Worker.find_by(work_number: time_log.worker)
        elsif Worker.where('name ILIKE ?', time_log.worker).any?
          worker = Worker.where('name ILIKE ?', time_log.worker).first
        end

        # convert date / hour start to time
        started_at = Time.strptime(time_log.started_on.strftime('%d/%m/%Y') + ' ' + time_log.hour_started_on.to_s, '%d/%m/%Y %H:%M:%S')
        duration = (time_log.duration * 3600).to_i
        # create time_logs
        unless worker.time_logs.find_by(started_at: started_at, duration: duration)
          worker.time_logs.create!(started_at: started_at, duration: duration)
        end

        w.check_point
      end
    end

    def provider_name
      :worker_time_logs
    end

    def open_and_decode_file(file)
      # Open and Decode: CSVReader::read(file)
      rows = ActiveExchanger::CsvReader.new(col_sep: ";", headers: true).read(file)
      parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

      parser.normalize(rows)
    end

  end
end
