# frozen_string_literal: true

module Ekylibre
  class OfxImportExchanger < ActiveExchanger::Base
    category :accountancy
    vendor :ekylibre

    # Import ofx bank statement
    def import
      # unzip of bank statement
      dir = w.tmp_dir
      Zip::File.open(file) do |zile|
        w.count = zile.count
        zile.each do |entry|
          file = dir.join(entry.name)
          FileUtils.mkdir_p(file.dirname)
          entry.extract(file)
        end
      end

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
