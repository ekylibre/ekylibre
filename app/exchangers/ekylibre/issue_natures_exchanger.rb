# frozen_string_literal: true

module Ekylibre
  class IssueNaturesExchanger < ActiveExchanger::Base
    category :plant_farming
    vendor :ekylibre

    def import
      s = Roo::OpenOffice.new(file)

      w.count = s.sheets.count

      s.each_with_pagename do |_name, sheet|
        sheet.parse(headers: true).each_with_index do |row, index|
          # Pass first row containing headers columns
          next if index.zero?

          IssueNature.find_or_create_by!(label: row['label'], nature: row['issue_natures'], category: row['category'])
        end
      end
    end
  end
end
