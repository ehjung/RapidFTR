Feature: Viewing all enquiries by different filters and ordering

Background: 
  Given I am logged in as an admin
  And the following enquiries exist in the system:
    | enquirer_name | name     | reporter | unique_id  | reunited | flag   | short_id  | created_at             | flagged_at                   | reunited_at                  |
    | Marsh         | Mallow   | zubair   | marsh_uid  | false    | true   | mar_uid   | 2020-01-01 03:02:01UTC | DateTime.new(2021,2,1,4,5,6) | DateTime.new(2102,2,3,4,5,6) |
    | Graham        | Crackers | zubair   | graham_uid | true     | false  | gra_uid   | 2014-03-28 04:05:06UTC | DateTime.new(2016,1,1,1,1,1) | DateTime.new(2091,2,3,4,5,6) |
    | Honey         | Dew      | zubair   | honey_uid  | false    | false  | hon_uid   | 2001-01-02 01:01:01UTC | DateTime.new(2002,2,1,4,5,6) | DateTime.new(2002,2,3,4,5,6) |
    And I am on the enquiries listing page

@wip
Scenario: Viewing enquiries filtered by All should by default show all enquiries in alphabetical order
  Then I should see the order Graham,Honey,Marsh
  And I should see "Enquirer Name"
  And I should see "ID Number"
  And I should see "Matches Found"
  And I should see "Registered By"
  And I should see "Last Updated"

@wip
Scenario: Viewing enquiries filtered by All and order by Most recently created
  And I select "Most recently created" from "order_by"
  Then I should see the order Marsh,Graham,Honey

@wip
Scenario: Viewing enquiries filtered by Active and ordered by Enquirer Name
  When I select "Active" from "filter"
  Then I should see "Marsh"
  And I should see "Honey"
  And I should not see "Graham"

@wip
Scenario: Viewing enquiries filtered by Reunited and ordered by Enquirer Name
  When I select "Reunited" from "filter"
  Then I should see "Graham"
  And I should not see "Marsh"
  And I should not see "Honey"

@wip
Scenario: Viewing enquiries filtered by Flagged and ordered by Enquirer Name
  When I select "Flagged" from "filter"
  Then I should see "Marsh"
  And I should not see "Graham"
  And I should not see "Honey"

@wip
Scenario: Viewing enquiries filtered by Active and ordered by Most recently created
  When I select "Active" from "filter"
  And I select "Most recently created" from "order_by"
  Then I should see the order Honey,Marsh
  And I should not see "Graham"