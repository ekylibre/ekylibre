require 'test_helper'

class ProgressTest < ActiveSupport::TestCase
  setup do
    FileUtils.rm_rf(Dir.glob(Ekylibre::Tenant.private_directory.join('tmp', 'imports', '*.progress')))
  end

  test 'progresses can be set values that can then be consulted later' do
    progress = Progress.new('Example', id: 1)
    progress.value = 2

    assert_equal 2, progress.value
  end

  test 'progresses\' values are set as a percentage from a specifiable max value' do
    progress = Progress.new('Not 100', id: 1, max: 40)
    progress.value = 3

    assert_equal 7.5, progress.value
  end

  test 'progresses can be incremented rather than be set to a specific value' do
    progress = Progress.new('Step by step', id: 1)
    progress.increment!

    assert_equal 1, progress.value

    progress.increment!

    assert_equal 2, progress.value
  end

  test 'progresses with different ids are separate' do
    first  = Progress.new('Test', id: 1)
    second = Progress.new('Test', id: 2)

    assert_not_equal first, second

    first.value = 1

    assert_not_equal 1, second.value
    assert_equal 0, second.value
  end

  test 'progresses with different names are separate' do
    first  = Progress.new('First',  id: 1)
    second = Progress.new('Second', id: 1)

    assert_not_equal first, second

    first.value = 1

    assert_not_equal 1, second.value
    assert_equal 0, second.value
  end

  test 'progresses can be fetched back after creation' do
    initialized = Progress.new('Initialized', id: 1)
    fetched = Progress.fetch('Initialized', id: 1)

    assert_equal initialized, fetched

    Progress.new('Not stored', id: 1).value = 2
    fetched = Progress.fetch('Not stored', id: 1)

    assert_equal 2, fetched.value
  end

  test 'progresses aren\'t reachable anymore once they have been cleared' do
    progress = Progress.new('To be cleared', id: 1)
    progress.value = 2
    progress.clear!

    assert_nil Progress.fetch('To be cleared', id: 1)
  end

  test 'cleared progresses are fetchable again if they are re-used' do
    progress = Progress.new('Lazarus', id: 1)
    progress.value = 2
    progress.clear!

    progress.value = 1 # Rise and walk

    assert_equal 1, progress.value
  end

  test 'cleared progresses have 0 as value' do
    progress = Progress.new('Zero', id: 1)
    progress.value = 2
    progress.clear!

    assert_equal 0, progress.value
  end

  test 'progresses can be set to read_only which prevents the modification of the value' do
    progress = Progress.new('Readonly', id: 1)
    progress.value = 3
    progress.read_only!

    assert_equal 3, progress.value

    assert_raise(Progress::ReadOnlyError) { progress.clear!     }
    assert_raise(Progress::ReadOnlyError) { progress.value = 5  }
    assert_raise(Progress::ReadOnlyError) { progress.increment! }
  end

  test 'fetch when a progress file exists but no Progress object instantiates a read-only progress' do
    path_to_file = Ekylibre::Tenant.private_directory.join('tmp', 'imports', 'external-1.progress')
    FileUtils.mkdir_p(path_to_file.dirname)
    File.write(path_to_file, '5')

    read_only_ext = Progress.fetch('External', id: 1)

    assert_not_nil read_only_ext, "Progress#fetch didn't find External."
    assert_equal 5, read_only_ext.value
    assert read_only_ext.read_only?
  end
end
