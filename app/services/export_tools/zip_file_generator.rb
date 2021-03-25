# frozen_string_literal: true

module ExportTools
  # Recursivly generates a zip file from the contents of
  # a specified directory. The directory itself is not
  # included in the archive, rather just its contents.
  class ZipFileGenerator
    # Zip the input directory.
    # @param [Pathname] path
    def compress_folder(path)
      Tempfile.create(['', '.zip']) do |tmpfile|
        ::Zip::File.open(tmpfile, ::Zip::File::CREATE) do |zipfile|
          recursively_deflate_directory(zipfile, root: path)
        end

        yield tmpfile.path
      end
    end

    private

      def write_entries(zipfile, entries:, relative_path:, root:)
        entries.each do |e|
          zipfile_path = File.join(*relative_path, e)
          disk_file_path = root.join(zipfile_path)

          if disk_file_path.directory?
            zipfile.mkdir(zipfile_path)
            recursively_deflate_directory(zipfile, root: root, relative_path: [*relative_path, e])
          else
            zipfile.add(zipfile_path, disk_file_path)
          end
        end
      end

      # @param [Zip::File] zipfile
      # @param [Pathname] root
      # @param [Array<String>] relative_path
      def recursively_deflate_directory(zipfile, root:, relative_path: [])
        entries = Dir.entries(root.join(*relative_path)) - %w[. ..]
        write_entries(zipfile, entries: entries, relative_path: relative_path, root: root)
      end
  end
end
