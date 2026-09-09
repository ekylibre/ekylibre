# frozen_string_literal: true

require 'test_helper'

module Ekylibre
  # Regression tests for the ZIP-slip fix in the exchangers.
  #
  # `Zip::Entry#extract` only checks `name_safe?` when called WITHOUT a
  # destination path ("the caller is responsible for making sure dest_path is
  # safe, if it is passed" — rubyzip). Every exchanger passed one, so the
  # library guard never ran and `dir.join(entry.name)` escaped the temporary
  # directory on a `../` entry name.
  class SafeZipTest < ActiveSupport::TestCase
    setup do
      @root = Pathname.new(Dir.mktmpdir('safe-zip-test'))
      @inside = @root.join('inside')
      @outside = @root.join('outside')
      FileUtils.mkdir_p([@inside, @outside])
    end

    teardown do
      FileUtils.rm_rf(@root)
    end

    test 'extracts a well-formed archive and returns the entry names' do
      archive = build_zip do |zip|
        zip.get_output_stream('a.txt') { |io| io.write('alpha') }
        zip.get_output_stream('nested/b.txt') { |io| io.write('beta') }
      end

      names = Ekylibre::SafeZip.extract_all(archive, into: @inside)

      assert_equal %w[a.txt nested/b.txt], names.sort
      assert_equal 'alpha', @inside.join('a.txt').read
      assert_equal 'beta', @inside.join('nested/b.txt').read
    end

    test 'refuses an entry escaping the destination through ..' do
      archive = build_zip do |zip|
        zip.get_output_stream('../outside/pwned.txt') { |io| io.write('pwned') }
      end

      assert_raises(Ekylibre::SafeZip::UnsafeEntry) do
        Ekylibre::SafeZip.extract_all(archive, into: @inside)
      end
      assert_not @outside.join('pwned.txt').exist?,
                 'ZIP slip: the archive wrote outside the destination directory'
    end

    test 'refuses a symlink entry' do
      source = @root.join('source')
      FileUtils.mkdir_p(source)
      File.symlink(@outside.to_s, source.join('link').to_s)

      archive = @root.join('symlink.zip')
      Zip::File.open(archive.to_s, Zip::File::CREATE) do |zip|
        zip.add('link', source.join('link').to_s)
      end

      assert_raises(Ekylibre::SafeZip::UnsafeEntry) do
        Ekylibre::SafeZip.extract_all(archive, into: @inside)
      end
      assert_not @inside.join('link').symlink?,
                 'a symlink entry would let a later entry write through it'
    end

    test 'count does not extract anything' do
      archive = build_zip do |zip|
        zip.get_output_stream('a.txt') { |io| io.write('alpha') }
        zip.get_output_stream('b.txt') { |io| io.write('beta') }
      end

      assert_equal 2, Ekylibre::SafeZip.count(archive)
      assert_empty @inside.children
    end

    private

      def build_zip
        path = @root.join("archive-#{SecureRandom.hex(4)}.zip")
        Zip::File.open(path.to_s, Zip::File::CREATE) { |zip| yield(zip) }
        path
      end
  end
end
