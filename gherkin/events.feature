Feature: Event sending behaviour

  Scenario: Events beyond the queue capacity are dropped
    Given an events client with a queue capacity of 2
    When 3 evaluate events are queued
    Then the event queue should contain 2 events

  Scenario: A 401 response permanently disables event sending
    Given a local events endpoint that responds with status 401
    And an events client pointed at the local endpoint
    When 2 evaluate events are queued
    And the event queue is flushed
    Then the events client should become disabled
    And the event queue should contain 0 events
    And queueing another evaluate event should leave the queue empty

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
    And the event queue should contain 2 events
    When the event queue is flushed
    Then the local endpoint should have received 1 request

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
