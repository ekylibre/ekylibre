module Rightable
  extend ActiveSupport::Concern

  included do
    serialize :rights

    before_validation do
      self.rights = self.rights.to_hash if self.rights
    end
  end

  # Returns rights as a list of "resource-action" strings
  def rights_array
    array = []
    each_right do |resource, action|
      array << resource + "-" + action
    end
    return array
  end


  # Returns rights as a list of "action-resource" strings
  def resource_actions
    array = []
    each_right do |resource, action|
      array << action + "-" + resource
    end
    return array
  end

  # Browse all resource/action pair
  def each_right(&block)
    return unless self.rights
    self.rights.each do |resource, actions|
      actions.each do |action|
        yield resource, action
      end
    end
  end


end
