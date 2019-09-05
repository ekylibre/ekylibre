require 'test_helper'

class RestfullyManageableTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
  Model = Class.new do
    def self.columns_definition
      { 'id' => "whatever" }
    end
  end

  setup do
    if defined? ModelController
      RestfullyManageableTest.send :remove_const, :ModelController
    end
    if defined? RestfullyManageable::Model
      RestfullyManageable.send :remove_const, :Model
    end

    class ModelController < ActionController::Base
      include RestfullyManageable
    end
    @kontroller = ModelController.new
  end

  test 'restfully_manageable doesn\'t define the actions' do
    initial_methods = ModelController.new.methods(false)
    ModelController.send(:manage_restfully, only: :index, model_name: 'RestfullyManageableTest::Model')
    after_restfully_methods = ModelController.new.methods(false)
    assert_equal after_restfully_methods, initial_methods
  end

  test 'restfully_manageable inserts a new module in the controller' do
    initial_parents = ModelController.ancestors
    ModelController.send(:manage_restfully, only: :index, model_name: 'RestfullyManageableTest::Model')
    after_restfully_parents = ModelController.ancestors
    difference = after_restfully_parents - initial_parents
    assert_equal difference.count, 1
    assert_equal difference.first.class, Module
  end

  test 'restfully_manageable does define controller methods' do
    controller = ModelController.new
    assert_not controller.respond_to? :index
    ModelController.send(:manage_restfully, only: :index, model_name: 'RestfullyManageableTest::Model')
    assert controller.respond_to? :index
  end
end
