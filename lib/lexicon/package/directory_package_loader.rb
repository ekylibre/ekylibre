# frozen_string_literal: true

module Lexicon
  module Package
    class DirectoryPackageLoader
      include Concerns::LoggerAware

      # @return [Pathname]
      attr_reader :root_dir

      # @param [Pathname] root_dir
      # @param [JSONSchemer::Schema] schema_validator
      def initialize(root_dir, schema_validator:)
        @root_dir = root_dir
        @schema_validator = schema_validator
      end

      # @param [String] name
      # @return [Package, nil]
      def load_package(name)
        package_dir = root_dir.join(name.to_s)

        if package_dir.directory?
          load_from_dir(package_dir)
        else
          nil
        end
      end

      protected

        def load_from_dir(dir)
          # @type [Pathname]
          spec_file = dir.join(::Lexicon::Package::Package::SPEC_FILE_NAME)
          # @type [Pathname]
          checksum_file = dir.join(::Lexicon::Package::Package::CHECKSUM_FILE_NAME)

          if spec_file.exist? && checksum_file.exist?
            json = JSON.parse(spec_file.read)

            if @schema_validator.valid?(json)
              version = Semantic::Version.new(json.fetch('version'))
              file_sets = json.fetch('content').map do |id, values|
                SourceFileSet.new(
                  id: id,
                  name: values.fetch('name'),
                  structure: values.fetch('structure'),
                  data: values.fetch('data', nil),
                  tables: values.fetch('tables', [])
                )
              end

              ::Lexicon::Package::Package.new(file_sets: file_sets, version: version, dir: dir, checksum_file: checksum_file, spec_file: spec_file)
            else
              log("Package at path #{dir} has invalid manifest")

              nil
            end
          else
            nil
          end
        end
    end
  end
end
