module Rightable
  extend ActiveSupport::Concern

  included do
    serialize :rights

    before_validation do
      self.rights = rights.to_hash if rights
    end
  end

  # Returns rights as a list of "resource-action" strings
  def rights_array
    array = []
    each_right do |resource, action|
      array << resource + '-' + action
    end
    array
  end

  # Returns rights as a list of "action-resource" strings
  def resource_actions
    array = []
    each_right do |resource, action|
      array << action + '-' + resource
    end
    array
  end

  # Browse all resource/action pair
  def each_right
    return unless rights
    rights.each do |resource, actions|
      actions.each do |action|
        yield resource, action
      end
    end
  end

  def right_exist?(action, resource)
    return false unless rights && rights[resource.to_s]
    return rights[resource.to_s].include?(action.to_s)
  end
end
