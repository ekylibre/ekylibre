Feature: Animal feature
  In order to manage my animal
  As a user
  I want to see my animals

  Scenario: View an animal
    Given an animal exists
    When I am on animals page 
    Then I should see "Animals"
