# frozen_string_literal: true

module Ekylibre
  class VegetativeStagesExchanger < ActiveExchanger::Base
    category :plant_farming
    vendor :ekylibre

    def import
      s = Roo::OpenOffice.new(file)

      w.count = s.sheets.count

      s.each_with_pagename do |_name, sheet|
        sheet.parse(headers: true).each_with_index do |row, index|
          # Pass first row containing headers columns
          next if index.zero?

          if (stage = VegetativeStage.where(bbch_number: row['reference'], variety: row['variety']).first)
            stage.update(label: row['label'])
          else
            VegetativeStage.create(bbch_number: row['reference'], label: row['label'], variety: row['variety'])
          end
        end
      end
    end
  end
end
