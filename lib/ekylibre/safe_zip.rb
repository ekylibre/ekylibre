module Ekylibre
  # Safe extraction of untrusted ZIP archives.
  #
  # `Zip::Entry#extract` only validates the entry name when it is called
  # WITHOUT a destination path ("the caller is responsible for making sure
  # dest_path is safe, if it is passed" — rubyzip). Every caller here passes
  # one, so the library guard never runs and `dir.join(entry.name)` happily
  # escapes `dir` on a `../../` entry name.
  #
  # This module re-establishes the guard: it resolves each destination and
  # refuses anything landing outside the target directory, plus symlink
  # entries (which would otherwise let a later entry write through them).
  module SafeZip
    class UnsafeEntry < StandardError; end

    class << self
      # Extracts every entry of an archive into a directory.
      #
      # @param archive [String, Pathname] the .zip file to read
      # @param into [String, Pathname] destination directory
      # @return [Array<String>] extracted entry names, in archive order
      # @raise [UnsafeEntry] if an entry escapes `into` or is a symlink
      def extract_all(archive, into:)
        root = Pathname.new(into).expand_path

        Zip::File.open(archive.to_s) do |zip|
          zip.map do |entry|
            if entry.symlink?
              raise UnsafeEntry.new("Refusing to extract symlink entry #{entry.name.inspect}")
            end

            target = destination_for(root, entry.name)
            FileUtils.mkdir_p(target.dirname)
            entry.extract(target.to_s)
            entry.name
          end
        end
      end

      # @return [Integer] number of entries, without extracting
      def count(archive)
        Zip::File.open(archive.to_s, &:count)
      end

      private

        # @raise [UnsafeEntry] when `name` resolves outside `root`
        def destination_for(root, name)
          target = root.join(name).expand_path

          unless target == root || target.to_s.start_with?("#{root}#{File::SEPARATOR}")
            raise UnsafeEntry.new("Refusing to extract #{name.inspect} outside #{root}")
          end

          target
        end
    end
  end
end
