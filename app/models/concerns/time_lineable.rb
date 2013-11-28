module TimeLineable
  extend ActiveSupport::Concern

  included do
    validates_presence_of :started_at, :if => :has_previous?
    validates_presence_of :stopped_at, :if => :has_followings?

    scope :at,     lambda { |at| where("? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?)", at, at, at) }
    scope :after,  lambda { |at| where("COALESCE(started_at, ?) > ?", at, at) }
    scope :before, lambda { |at| where("COALESCE(started_at, ?) < ?", at, at) }

    before_validation do
      if following = siblings.after(self.started_at).order(:started_at).first
        self.stopped_at = following.started_at
      else
        self.stopped_at = nil
      end
    end

    after_save do
      self.previous.update_column(:stopped_at, self.started_at) if self.previous
    end

    after_destroy do
      self.previous.update_column(:stopped_at, self.stopped_at) if self.previous
    end
  end

  def previous
    return nil unless self.started_at
    return siblings.find_by(stopped_at: self.started_at)
  end

  def following
    return nil unless self.stopped_at
    return siblings.find_by(started_at: self.stopped_at)
  end

  def has_previous?
    siblings.before(self.started_at).any?
  end

  def has_followings?
    siblings.after(self.started_at).any?
  end

  private

  def siblings
    raise NotImplementedError, "Private method :siblings must be implemented"
  end

end
