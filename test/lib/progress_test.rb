require 'test_helper'

class ProgressTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    FileUtils.rm_rf(Dir.glob(Ekylibre::Tenant.private_directory.join('tmp', 'imports', '*.progress')))
    Progress.instance_variable_set(:@progresses, nil)
  end

  test 'progresses can be set values that can then be consulted later' do
    progress = Progress.new('Example')
    progress.value = 2

    assert_equal 2, progress.value
  end

  test 'progresses\' values are set as a percentage from a specifiable max value' do
    progress = Progress.new('Not 100', max: 40)
    progress.value = 3

    assert_equal 7.5, progress.value
  end

  test 'progresses can be incremented rather than be set to a specific value' do
    progress = Progress.new('Step by step')
    progress.increment!

    assert_equal 1, progress.value

    progress.increment!

    assert_equal 2, progress.value
  end

  test 'progresses can be specified ids to be kept separate in case of possible similar progresses running' do
    first  = Progress.new('Test', id: 1)
    second = Progress.new('Test', id: 2)

    assert_not_equal first, second

    first.value = 1

    assert_not_equal 1, second.value
    assert_equal 0, second.value
  end

  test 'progresses with different names are separate' do
    first  = Progress.new('First')
    second = Progress.new('Second')

    assert_not_equal first, second

    first.value = 1

    assert_not_equal 1, second.value
    assert_equal 0, second.value
  end

  test 'progresses can be fetched back after creation' do
    initialized = Progress.new('Initialized')
    fetched = Progress.fetch('Initialized')

    assert_equal initialized, fetched

    Progress.new('Not stored').value = 2
    fetched = Progress.fetch('Not stored')

    assert_equal 2, fetched.value
  end

  test 'progresses aren\'t reachable anymore once they have been cleared' do
    progress = Progress.new('To be cleared')
    progress.value = 2
    progress.clear!

    assert_nil Progress.fetch('To be cleared')
  end

  test 'cleared progresses are fetchable again if they are re-used' do
    progress = Progress.new('Lazarus')
    progress.value = 2
    progress.clear!

    progress.value = 1 # Rise and walk

    assert_equal 1, progress.value
  end

  test 'cleared progresses have 0 as value' do
    progress = Progress.new('Zero')
    progress.value = 2
    progress.clear!

    assert_equal 0, progress.value
  end

  test 'fetch when a progress file exists but no Progress object instantiates a read-only progress' do
    path_to_file = Ekylibre::Tenant.private_directory.join('tmp', 'imports', 'external-0.progress')
    FileUtils.mkdir_p(path_to_file.dirname)
    File.write(path_to_file, '5')

    read_only_ext = Progress.fetch('External')

    assert_not_nil read_only_ext, "Progress#fetch didn't find External."
    assert_equal 5, read_only_ext.value
    assert read_only_ext.read_only?
  end

  test 'progress#increment! is able to handle non-100 @maxs' do
    lil_max = Progress.new('Little Max', max: 4)
    lil_max.increment!
    lil_max.increment!
    lil_max.increment!

    assert_equal 75, lil_max.value
  end

  test 'progress value can be expressed as a direct value (no percentage)' do
    weird_max = Progress.new('Direct', max: 5)
    weird_max.value = 1

    assert_equal 20, weird_max.value
    assert_equal 1,  weird_max.value(percentage: false)
  end
end
