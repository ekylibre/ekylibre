# language: en
Feature: Connect to back-end
  In order to use to back end
  As a user
  I want to log in

  Scenario: Simple connection
    Given I am on the login page
    When I fill in "name" with "gendo"
    And I fill in "password" with "secret"
    And I press "Login"
    Then I am redirected to the general dashboard page
