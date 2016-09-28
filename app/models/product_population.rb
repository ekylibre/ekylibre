
# Sum of all the deltas in product movements up to and including a date.
class ProductPopulation < Ekylibre::Record::Base
  belongs_to :product

  scope :chain,                   ->(product) { where(product: product).order(started_at: :asc) }
  scope :initial_population_for,  ->(product) { chain(product).first }
  scope :at,                      ->(time)    { where(started_at: time) }
  scope :last_before,             ->(time)    { where(arel_table[:started_at].lt(time)).reorder(started_at: :desc).limit(1) }
  scope :first_after,             ->(time)    { where(arel_table[:started_at].gt(time)).reorder(started_at: :asc).limit(1) }

  validate do
    errors.add(movements, :invalid) if movements.none?
  end

  # More performance.
  def self.compute_values_for!(product)
    chain(product).find_each(&:compute_value!)
  end

  def compute_value!(impact_on_following: false)
    return destroy if movements.none?

    previous = Maybe(previous_population)
    update(value: movements.sum(:delta) + previous.value.or_else(0))

    if following_population.present?
      update(stopped_at: following_population.started_at)
      following_population.compute_value!(impact_on_following: impact_on_following) if impact_on_following
    end
  end

  def chain
    self.class.chain(product)
  end

  def siblings
    chain.where.not(id: id)
  end

  def previous_population
    siblings.last_before(started_at).first
  end

  def following_population
    siblings.first_after(started_at).first
  end

  def movements
    ProductMovement.where(product: product, started_at: started_at)
  end
end
