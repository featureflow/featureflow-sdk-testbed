Feature: Per-flag exposure fidelity (trackEvents)

  A feature control may carry "trackEvents": true in the /features payload (dormant until
  server-side experimentation ships). For such flags the SDK attaches each distinct user
  once per (user, flag) per flush interval — instead of the global once-per-user dedupe —
  so every (user, flag, variant) assignment reaches the server for experiment analysis.

  Scenario: a tracked flag attaches every distinct user each interval
    Given an events client
    When 1 evaluate events are queued for tracked feature "exp1" variant "on" user "u1"
    And 1 evaluate events are queued for tracked feature "exp1" variant "on" user "u2"
    And 1 evaluate events are queued for tracked feature "exp1" variant "on" user "u1"
    Then the pending summary for feature "exp1" variant "on" should have 3 impressions
    And the pending summary entry for feature "exp1" variant "on" should include user "u1"
    And the pending summary entry for feature "exp1" variant "on" should include user "u2"

  Scenario: a tracked flag records a user already sent for another flag this interval
    Given an events client
    When 1 evaluate events are queued for feature "f1" variant "on" user "u1"
    And 1 evaluate events are queued for tracked feature "exp1" variant "on" user "u1"
    Then the pending summary entry for feature "exp1" variant "on" should include user "u1"

  Scenario: a tracked flag still dedupes repeat exposures of the same user and flag
    Given an events client
    When 2 evaluate events are queued for tracked feature "exp1" variant "on" user "u1"
    Then the pending summary for feature "exp1" variant "on" should have 2 impressions
    And the pending summary entry for feature "exp1" variant "on" should include only user "u1"

  Scenario: evaluate passes a feature's trackEvents flag through to the recorded event
    Given a Featureflow client with the stored features
      | key  | enabled | offVariantKey | defaultVariant | trackEvents |
      | exp1 | true    | off           | on             | true        |
      | f1   | true    | off           | on             |             |
    When evaluate "exp1" is called for user "user-1" and isOn is checked
    And evaluate "f1" is called for user "user-1" and isOn is checked
    Then the recorded evaluate event for "exp1" should have trackEvents true
    And the recorded evaluate event for "f1" should have trackEvents false
