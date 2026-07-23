Feature: Event sending behaviour

  Evaluate events are summarised client-side: the SDK keeps one pending entry per
  (featureKey, evaluatedVariant) pair with an impression count, instead of queueing one
  raw event per evaluation. Each distinct user is attached to at most one entry per
  flush interval so the server still learns every user's attributes.

  Scenario: Evaluations of the same feature and variant are summarised into one entry
    Given an events client
    When 3 evaluate events are queued for feature "f1" variant "on" user "u1"
    Then the pending summary should contain 1 entries
    And the pending summary for feature "f1" variant "on" should have 3 impressions

  Scenario: Different variants of the same feature are summarised separately
    Given an events client
    When 1 evaluate events are queued for feature "f1" variant "on" user "u1"
    And 1 evaluate events are queued for feature "f1" variant "off" user "u2"
    Then the pending summary should contain 2 entries
    And the pending summary for feature "f1" variant "on" should have 1 impressions
    And the pending summary for feature "f1" variant "off" should have 1 impressions

  Scenario: Summary entries beyond capacity are dropped
    Given an events client with a summary capacity of 2
    When 3 evaluate events are queued
    Then the pending summary should contain 2 entries

  Scenario: Impressions are still counted while the summary is at capacity
    Given an events client with a summary capacity of 1
    When 1 evaluate events are queued for feature "f1" variant "on" user "u1"
    And 1 evaluate events are queued for feature "f2" variant "on" user "u2"
    And 1 evaluate events are queued for feature "f1" variant "on" user "u1"
    Then the pending summary should contain 1 entries
    And the pending summary for feature "f1" variant "on" should have 2 impressions

  Scenario: A user is attached to at most one summary entry per flush interval
    Given an events client
    When 1 evaluate events are queued for feature "f1" variant "on" user "u1"
    And 1 evaluate events are queued for feature "f2" variant "on" user "u1"
    Then the pending summary entry for feature "f1" variant "on" should include user "u1"
    And the pending summary entry for feature "f2" variant "on" should include no users

  Scenario: The flushed batch reports summed impressions and each distinct user once
    Given a local events endpoint that responds with status 200
    And an events client pointed at the local endpoint
    When 2 evaluate events are queued for feature "f1" variant "on" user "u1"
    And 1 evaluate events are queued for feature "f1" variant "on" user "u2"
    And the event queue is flushed
    Then the local endpoint should have received a batch of 2 events
    And the batch should total 3 impressions for feature "f1" variant "on"
    And the batch should include users "u1" and "u2"
    And the batch events should not include an expectedVariant

  Scenario: A user is sent again in the next flush interval
    Given a local events endpoint that responds with status 200
    And an events client pointed at the local endpoint
    When 1 evaluate events are queued for feature "f1" variant "on" user "u1"
    And the event queue is flushed
    And 1 evaluate events are queued for feature "f1" variant "on" user "u1"
    Then the pending summary entry for feature "f1" variant "on" should include user "u1"

  Scenario: A 401 response permanently disables event sending
    Given a local events endpoint that responds with status 401
    And an events client pointed at the local endpoint
    When 2 evaluate events are queued
    And the event queue is flushed
    Then the events client should become disabled
    And the pending summary should contain 0 entries
    And queueing another evaluate event should leave the summary empty

  Scenario: A 403 response permanently disables event sending
    Given a local events endpoint that responds with status 403
    And an events client pointed at the local endpoint
    When 2 evaluate events are queued
    And the event queue is flushed
    Then the events client should become disabled

  Scenario: A 429 response requeues the batch and backs off
    Given a local events endpoint that responds with status 429 and Retry-After 60
    And an events client pointed at the local endpoint
    When 2 evaluate events are queued
    And the event queue is flushed
    Then the events client should be backing off
    And the pending summary should contain 2 entries
    When the event queue is flushed
    Then the local endpoint should have received 1 request

  Scenario: A 429 response merges the rejected batch back into the pending summary
    Given a local events endpoint that responds with status 429 and Retry-After 60
    And an events client pointed at the local endpoint
    When 1 evaluate events are queued for feature "f1" variant "on" user "u1"
    And the event queue is flushed
    Then the events client should be backing off
    When 1 evaluate events are queued for feature "f1" variant "on" user "u1"
    Then the pending summary for feature "f1" variant "on" should have 2 impressions

  Scenario: A 429 response without Retry-After uses the default backoff
    Given a local events endpoint that responds with status 429
    And an events client pointed at the local endpoint
    When 1 evaluate events are queued
    And the event queue is flushed
    Then the events client should be backing off

  Scenario: evaluateAll does not record evaluation events
    Given a Featureflow client with the stored features
      | key | enabled | offVariantKey | defaultVariant |
      | f1  | true    | off           | on             |
      | f2  | false   | off           | on             |
    When evaluateAll is called for user "user-1"
    Then the evaluated features should be
      | key | variant |
      | f1  | on      |
      | f2  | off     |
    And no evaluate events should have been recorded

  Scenario: evaluate still records an evaluation event
    Given a Featureflow client with the stored features
      | key | enabled | offVariantKey | defaultVariant |
      | f1  | true    | off           | on             |
    When evaluate "f1" is called for user "user-1" and isOn is checked
    Then 1 evaluate event should have been recorded
