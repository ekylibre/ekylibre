require 'test_helper'

class BookkeeperTestCase < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  attr_reader :bookkeeper

  private

  def bookkeep(resource)
    initialize_bookkeeper(resource)
    bookkeeper.call
  end

  def initialize_bookkeeper(resource)
    @recorder = TestBookkeepRecorder.new(resource)
    bookkeeper_klass = self.class.name.gsub(/Test$/, '').constantize
    @bookkeeper = bookkeeper_klass.new(@recorder)
  end

  def entries_bookkeeped
    @recorder.entries
  end
end

class TestBookkeepRecorder
  attr_reader :resource, :entries

  def initialize(resource)
    @resource = resource
    @entries = []
  end

  def journal_entry(journal, options = {})
    return if (options.key?(:unless) && options[:unless])
    return if (options.key?(:if) && !options[:if])

    entry = TestEntry.new(journal: journal)
    yield entry
    @entries << entry
  end
end

class TestEntry
  attr_reader :debits, :credits

  def initialize(journal)
    @debits  = []
    @credits = []
    @journal = journal
  end

  def add_debit(*args)
    debits << args
  end

  def add_credit(*args)
    credits << args
  end
end
