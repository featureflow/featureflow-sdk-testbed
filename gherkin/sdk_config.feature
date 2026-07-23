Feature: Server-driven SDK config

  The server steers event behaviour via a JSON config object — delivered as the
  X-Featureflow-Sdk-Config response header on /features (200 and 304) and as the
  /events POST response body. Fields: eventsEnabled, mode (summary|full|off),
  flushIntervalSeconds. See SDK-CONFIG.md for the full contract.

  Scenario: eventsEnabled false suspends event recording and clears pending events
    Given an events client
    When 2 evaluate events are queued
    And the server config is applied
      """
      {"eventsEnabled": false}
      """
    Then the pending summary should contain 0 entries
    When 1 evaluate events are queued
    Then the pending summary should contain 0 entries

  Scenario: eventsEnabled true resumes event recording
    Given an events client
    When the server config is applied
      """
      {"eventsEnabled": false}
      """
    And 1 evaluate events are queued
    And the server config is applied
      """
      {"eventsEnabled": true}
      """
    And 1 evaluate events are queued
    Then the pending summary should contain 1 entries

  Scenario: mode off stops event recording
    Given an events client
    When the server config is applied
      """
      {"mode": "off"}
      """
    And 2 evaluate events are queued
    Then the pending summary should contain 0 entries

  Scenario: mode full records one event per evaluation with the user on every event
    Given an events client
    When the server config is applied
      """
      {"mode": "full"}
      """
    And 2 evaluate events are queued for feature "f1" variant "on" user "u1"
    Then the pending summary should contain 2 entries
    And every pending entry should have 1 impression and user "u1"

  Scenario: flushIntervalSeconds restarts the flush timer
    Given an events client
    When the server config is applied
      """
      {"flushIntervalSeconds": 30}
      """
    Then the events client send interval should be 30 seconds

  Scenario: invalid config values are ignored field by field
    Given an events client
    When the server config is applied
      """
      {"eventsEnabled": "yes", "mode": "banana", "flushIntervalSeconds": -5}
      """
    Then the events client send interval should be 60 seconds
    And the events client should not be suspended
    When 1 evaluate events are queued
    Then the pending summary should contain 1 entries

  Scenario: server config cannot re-enable a locally disabled events client
    Given a disabled events client
    When the server config is applied
      """
      {"eventsEnabled": true}
      """
    And 1 evaluate events are queued
    Then the pending summary should contain 0 entries

  Scenario: the events response body applies server config
    Given a local events endpoint that responds with status 200 and config body
      """
      {"eventsEnabled": false, "mode": "summary", "flushIntervalSeconds": 120}
      """
    And an events client pointed at the local endpoint
    When 1 evaluate events are queued
    And the event queue is flushed
    Then the events client should become suspended
    And the events client send interval should be 120 seconds

  Scenario: the features response config header applies server config
    Given a local features endpoint with config header
      """
      {"eventsEnabled": false, "flushIntervalSeconds": 300}
      """
    And a Featureflow client pointed at the local features endpoint
    Then the events client should become suspended
    And the events client send interval should be 300 seconds

  Scenario: pollIntervalSeconds retunes the features polling timer
    Given a local features endpoint with config header
      """
      {"pollIntervalSeconds": 60}
      """
    And a polling Featureflow client pointed at the local features endpoint
    Then the polling interval should become 60 seconds

  Scenario: server config never re-enables locally disabled polling
    Given a local features endpoint with config header
      """
      {"pollIntervalSeconds": 60}
      """
    And a Featureflow client pointed at the local features endpoint
    Then the polling interval should remain 0

  Scenario: the client emits updated when a poll observes changed features
    Given a local features endpoint whose features change on every request
    And a polling Featureflow client pointed at the local features endpoint
    When the features are refreshed
    Then the client should have emitted 1 updated event
