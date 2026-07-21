# Whether implicit attributes (featureflow.user.id, featureflow.date, featureflow.hourofday)
# are injected by the UserBuilder at build time, or later by Client#evaluate at evaluation
# time, is a legitimate per-SDK architecture choice (see e.g. featureflow-ruby-sdk's
# CLAUDE.md, which injects at evaluate time so date/hour rules match "now" rather than
# build time). The @builder-injects-implicit-attributes scenario below only applies to
# SDKs that inject at build time — skip it (tag-exclude) for SDKs that inject at evaluate
# time instead. Every SDK must still support these attributes being present when a rule is
# matched; that's covered by rules.feature's featureflow.date scenario, which supplies the
# attribute explicitly rather than relying on either injection point.
Feature: UserBuilder
  Scenario: Test the User Builder can build a valid user with an id
    Given there is access to the User Builder module
    When the builder is initialised with the id "user"
    And the user is built using the builder
    Then the result user should have an id "user"
    And the result user should have no attributes

  Scenario: Test the User Builder can build a valid user with attributes
    Given there is access to the User Builder module
    When the builder is initialised with the id "user"
    And the builder is given the following attributes
      | key  | value  |
      | age  | 21     |
      | type | beta   |
    And the user is built using the builder
    Then the result user should have an id "user"
    And the result user should have a attribute with key "age" and value "21"
    And the result user should have a attribute with key "type" and value "beta"

  @builder-injects-implicit-attributes
  Scenario: Test the User Builder injects implicit attributes at build time
    Given there is access to the User Builder module
    When the builder is initialised with the id "user"
    And the builder is given the following attributes
      | key  | value  |
      | age  | 21     |
      | type | beta   |
    And the user is built using the builder
    Then the result user should have a attribute with key "featureflow.user.id" and value "user"
    And the result user should have a attribute with key "featureflow.date" and current datetime in iso8601

  Scenario: Test the User Builder throws an error when no key is provided
    Given there is access to the User Builder module
    When the builder is initialised with the id ""
    Then the builder should throw an error
