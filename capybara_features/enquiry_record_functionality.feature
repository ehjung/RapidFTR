Feature: Viewing all enquiries by different filters and ordering

Background: 
  Given I am logged in as an admin
  And the following enquiries exist in the system:
    | enquirer_name | name     | reporter | unique_id  | reunited | flag   | short_id  | created_at             | flagged_at                   | reunited_at                  |
    | Graham        | Crackers | zubair   | graham_uid | true     | false  | gra_uid   | 2014-03-28 04:05:06UTC | DateTime.new(2080,1,1,1,1,1) | DateTime.new(2091,2,3,4,5,6) |
    | Marsh         | Mallow   | zubair   | marsh_uid  | false    | true   | mar_uid   | 2100-01-01 03:02:01UTC | DateTime.new(2101,2,1,4,5,6) | DateTime.new(2102,2,3,4,5,6) |
    | Honey         | Dew      | zubair   | honey_uid  | false    | false  | hon_uid   | 2001-01-02 01:01:01UTC | DateTime.new(2002,2,1,4,5,6) | DateTime.new(2002,2,3,4,5,6) |

Scenario: Viewing enquiries filtered by All should by default show all enquiries in alphabetical order
  Then I should see the order Graham, Honey, Marsh
  And I should see the basic details Enquirer Name, ID Number, Matches Found, Registered By and Last Updated fields

Scenario: Viewing enquiries filtered by All and order by Most recently created
  When I select "Most recently created" from "Order by"
  Then I should see the order Marsh, Graham, Honey

Scenario: Viewing enquiries filtered by Active and ordered by Enquirer Name
  When I select "Active" from "Filter by"
  Then I should see "Marsh"
  And I should see "Honey"
  And I should not see "Graham"

Scenario: Viewing enquiries filtered by Reunited and ordered by Enquirer Name
  When I select "Reunited" from "Filter by"
  Then I should see "Graham"
  And I should not see "Marsh"
  And I should not see "Honey"

Scenario: Viewing enquiries filtered by Flagged and ordered by Enquirer Name
  When I select "Flagged" from "Filter by"
  Then I should see "Marsh"
  And I should not see "Graham"
  And I should not see "Honey"

Scenario: Viewing enquiries filtered by Active and ordered by Most recently created
  When I select "Active" from "Filter by"
  And I select "Most recently created" from "Order by"
  Then I should see the order Honey, Marsh
  And I should not see "Graham"