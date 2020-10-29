class SequenceManager
  def initialize(klass, options)
    options = { force: true }.merge(options)

    @managed  = klass

    @start    = options[:start]
    @usage    = options[:usage]
    @force    = options[:force]
    @column   = options[:column]
    @readonly = options[:readonly]
  end

  def last_numbered_record
    @managed
      .where.not(@column => nil)
      .reorder("LENGTH(#{@column}) DESC, #{@column} DESC")
      .first
  end

  def next_number
    return sequence.next_value if sequence

    last = last_numbered_record
    return @start if last.blank?

    number_of(last).succ
  end

  def unique_predictable
    value = next_number
    used_values = @managed.pluck(@column).to_set
    value = value.succ while used_values.include? value
    value
  end

  def unique_reliable
    value = sequence.next_value!
    used_values = @managed.pluck(@column).to_set
    value = sequence.next_value! while used_values.include? value
    value
  end

  def load_predictable_into(record)
    return true unless @force || number_of(record).nil?
    set_number(record, unique_predictable)
    true
  end

  def load_reliable_into(record)
    return true unless @force || number_of(record).nil?
    return load_predictable_into(record) unless sequence
    set_number(record, unique_reliable)
    true
  end

  def set_number(record, value)
    record.send(:"#{@column}=", value)
  end

  def number_of(record)
    record.send(@column)
  end

  def sequence
    @sequence &&= Sequence.find_by(usage: @usage, id: @sequence.id)
    @sequence ||= Sequence.of(@usage)
  end
end
