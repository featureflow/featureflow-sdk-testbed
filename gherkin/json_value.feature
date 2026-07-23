# jsonValue() (a JSON config payload carried by a variant, in addition to its key) is
# currently only implemented by the JS-family SDKs (featureflow-javascript-sdk,
# react-featureflow-client, featureflow-react-native) — see the "JSON Config Payloads on
# Variants" plan. Not yet part of the universal cross-SDK contract; tagged so SDKs
# without a jsonValue()-equivalent can exclude it rather than treat it as a required
# scenario.
@json-value
Feature: JSON Value Resolution
  Scenario: jsonValue returns the JSON config value for the evaluated variant
    Given the feature "my-feature" evaluates to variant "on" with variants
      | key | value                              |
      | on  | {"color":"#0066cc","maxItems":10}   |
      | off |                                     |
    When jsonValue is called
    Then the json value should equal
      """
      {"color":"#0066cc","maxItems":10}
      """

  Scenario: jsonValue returns undefined when the evaluated variant has no value
    Given the feature "my-feature" evaluates to variant "off" with variants
      | key | value                              |
      | on  | {"color":"#0066cc","maxItems":10}   |
      | off |                                     |
    When jsonValue is called
    Then the json value should be undefined

  Scenario: jsonValue returns undefined when the feature has no variants at all
    Given the feature "my-feature" evaluates to variant "on" with no variants
    When jsonValue is called
    Then the json value should be undefined

  Scenario: value() still returns the variant key string, unaffected by jsonValue
    Given the feature "my-feature" evaluates to variant "on" with variants
      | key | value                              |
      | on  | {"color":"#0066cc","maxItems":10}   |
      | off |                                     |
    When value is called
    Then the result should be "on"

  Scenario: jsonValue records an evaluation event but never leaks the JSON value into it
    Given the feature "my-feature" evaluates to variant "on" with variants
      | key | value                              |
      | on  | {"color":"#0066cc","maxItems":10}   |
      | off |                                     |
    When jsonValue is called
    Then an evaluate event should be queued with featureKey "my-feature" and evaluatedVariant "on"
    And the queued event should only have keys "featureKey, evaluatedVariant, user"
