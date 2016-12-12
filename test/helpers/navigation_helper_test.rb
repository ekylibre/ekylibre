require 'test_helper'

class NavigationHelperTest < ActionView::TestCase
  setup do
    Entity.delete_all # Making sure nobody ruins the order.

    @max      = Entity.create!(first_name: 'Max',      last_name: 'Rockatansky', nature: 'contact')
    @furiosa  = Entity.create!(first_name: 'Furiosa',  last_name: 'Imperator',   nature: 'contact')
    @immortan = Entity.create!(first_name: 'Immortan', last_name: 'Joe',         nature: 'contact')

    @furiosa.transporter = true
    @max.transporter     = true
    @furiosa.save!
    @max.save!

    @view_flow = ActionView::OutputFlow.new # Necessary for content_for testing.
  end

  test 'uses id by default if order unspecified' do
    navigation @furiosa
    previous_link, following_link = *links_in(content_in(:heading_toolbar))

    assert_equal @max.id,      record_id_in(previous_link)
    assert_equal @immortan.id, record_id_in(following_link)
  end

  test 'can be ordered by other attribute' do
    navigation @immortan, order: :first_name
    previous_link, following_link = *links_in(content_in(:heading_toolbar))

    assert_equal @furiosa.id, record_id_in(previous_link)
    assert_equal @max.id,     record_id_in(following_link)
  end

  test 'order can be descending' do
    navigation @immortan, order: { first_name: :desc }
    previous_link, following_link = *links_in(content_in(:heading_toolbar))

    assert_equal @max.id,     record_id_in(previous_link)
    assert_equal @furiosa.id, record_id_in(following_link)
  end

  test 'records can be scoped' do
    navigation @furiosa, scope: :transporters
    previous_link, following_link = *links_in(content_in(:heading_toolbar))

    assert_equal @max.id, record_id_in(previous_link)
    assert_nil            record_id_in(following_link)
  end

  test 'records are labelled using #name by default' do
    navigation @furiosa
    previous_link, following_link = *links_in(content_in(:heading_toolbar))

    assert_equal 'Max Rockatansky', label_in(previous_link)
    assert_equal 'Immortan Joe',    label_in(following_link)
  end

  test 'naming method can be specified' do
    navigation @furiosa, naming_method: :last_name
    previous_link, following_link = *links_in(content_in(:heading_toolbar))

    assert_equal 'Rockatansky', label_in(previous_link)
    assert_equal 'Joe',         label_in(following_link)
  end

  test 'raise error if scope doesn\'t exist' do
    assert_raises(MissingScopeError) do
      navigation @max, scope: :war_boys
    end
  end

  test 'raise error if order criterion doesn\'t exist' do
    assert_raises(OrderingCriterionNotFound) do
      navigation @max, order: :badassness
    end
  end

  private

  Struct.new('Link', :url, :label)

  def content_in(identifier)
    @view_flow.content[identifier]
  end

  def links_in(text)
    link_url   = /(?:<a href=\"(.*?)\".*>)+/
    link_title = %r{(?:<.*?>(.*?)<\/.*?>)+}
    urls   = text.scan(link_url).flatten
    titles = text.scan(link_title).flatten
    titles.map.each_with_index do |title, index|
      Struct::Link.new(urls[index], title)
    end
  end

  def label_in(link)
    return nil unless link.present?
    link.label
  end

  def record_id_in(link)
    return nil unless link.present?
    link.url.split('/').last.to_i
  end
end
