# frozen_string_literal: true

module Ekylibre
  class OfxImportExchanger < ActiveExchanger::Base
    category :accountancy
    vendor :ekylibre

    # Import ofx bank statement
    def import
      # unzip of bank statement
      dir = w.tmp_dir
      w.count = Ekylibre::SafeZip.count(file)
      Ekylibre::SafeZip.extract_all(file, into: dir)

      Dir.chdir(dir) do
        Dir.glob('*') do |file|
          ofx = OfxImport.new(File.open(file))
          ofx.run
          w.check_point
        end
      end
      true
    end
  end
end
