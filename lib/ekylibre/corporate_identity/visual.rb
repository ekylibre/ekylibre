module Ekylibre
  module CorporateIdentity
    class Visual
      def self.set_default_background(file)
        dest = Ekylibre::CorporateIdentity::Visual.path(:default)

        FileUtils.mkdir_p dest.dirname

        `convert #{file} #{dest}`
      end

      def self.path(name = :default)
        Ekylibre::Tenant.private_directory.join('corporate_identity', 'visuals', "#{name}.jpg")
      end

      def self.file?
        path(:default).exist?
      end

      def self.url
        '/backend/visuals/default/picture.jpg'
      end
    end
  end
end
