Feature: Goal tracking events

  track(goalKey, user, details?) records a goal event — the outcome half of
  experimentation. Goals are sent raw (never summarised) alongside the evaluate batch;
  analysis joins them against exposures on the user id. The details argument is a number
  (the metric value) or an object with optional numeric "value" plus custom fields,
  matching the OpenFeature tracking API. See SDK-CONFIG.md, "Related dormant wire
  contracts".

  Scenario: track queues a goal event carrying the user
    Given an events client
    When goal "signup" is tracked for user "u1"
    Then the pending goals should contain 1 events
    And the pending goal "signup" should have user "u1"

  Scenario: track with a numeric value
    Given an events client
    When goal "checkout-value" is tracked for user "u1" with value 129.9
    Then the pending goal "checkout-value" should have value 129.9

  Scenario: track with a details object records value and custom data
    Given an events client
    When goal "purchase" is tracked for user "u1" with details
      """
      {"value": 5, "plan": "pro"}
      """
    Then the pending goal "purchase" should have value 5
    And the pending goal "purchase" should have data
      """
      {"plan": "pro"}
      """

  Scenario: goals are flushed in the same batch as evaluate events
    Given a local events endpoint that responds with status 200
    And an events client pointed at the local endpoint
    When 1 evaluate events are queued for feature "f1" variant "on" user "u1"
    And goal "signup" is tracked for user "u1"
    And the event queue is flushed
    Then the local endpoint should have received a batch of 2 events
    And the batch should include a goal event "signup" with type "goal" and no featureKey

  Scenario: goals alone are flushed even with no evaluate events pending
    Given a local events endpoint that responds with status 200
    And an events client pointed at the local endpoint
    When goal "signup" is tracked for user "u1"
    And the event queue is flushed
    Then the local endpoint should have received a batch of 1 events

  Scenario: goals are dropped while suspended
    Given an events client
    When the server config is applied
      """
      {"eventsEnabled": false}
      """
    And goal "signup" is tracked for user "u1"
    Then the pending goals should contain 0 events

  Scenario: a 429 response requeues goals with backoff
    Given a local events endpoint that responds with status 429 and Retry-After 60
    And an events client pointed at the local endpoint
    When goal "signup" is tracked for user "u1"
    And the event queue is flushed
    Then the events client should be backing off
    And the pending goals should contain 1 events
