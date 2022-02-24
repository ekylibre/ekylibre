# frozen_string_literal: true

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
    each_right do |category, resource, action|
      array << category + '-' +resource + '-' + action
    end
    array
  end

  # Returns rights as a list of "action-resource" strings
  def resource_actions
    array = []
    each_right do |category, resource, action|
      array << action + '-' +resource + '-' + category
    end
    array
  end

  # Browse all resource/action pair
  def each_right
    return unless rights

    rights.each do |category, resources|
      resources.each do |resource, actions|
        actions.each do |action|
          yield category, resource, action
        end
      end
    end
  end

  def right_exist?(action, resource, category)
    return false unless rights && rights[category.to_s] && rights[category.to_s][resource.to_s]

    rights[category.to_s][resource.to_s].include?(action.to_s)
  end
end
