# frozen_string_literal: true

module Ekylibre
  module DocumentManagement
    class PdfConverter
      class << self
        def build
          new
        end
      end

      # @param [Array<byte>] odt_data
      # @return [Array<byte>]
      def convert_data(odt_data)
        Dir.mktmpdir do |dir|
          path = Pathname.new(dir)

          odt = path.join('source.odt')
          odt.binwrite(odt_data)
          convert_to_pdf(path, odt)

          pdf = path.join('source.pdf')

          pdf.binread
        end
      end

      private

        def convert_to_pdf(directory, odf_path)
          Dir.mktmpdir('libreoffice_home') do |lo_home|
            system "soffice --headless --convert-to pdf -env:UserInstallation=file://#{lo_home} --outdir #{directory} #{odf_path}"
          end
        end
    end
  end
end
