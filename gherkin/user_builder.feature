# Whether implicit attributes (featureflow.user.id, featureflow.date, featureflow.hourofday)
# are injected by the UserBuilder at build time, or later by Client#evaluate at evaluation
# time, is a legitimate per-SDK architecture choice. SDKs that inject at evaluate time
# (e.g. Ruby, Go) do so precisely so date/hour rules match "now" rather than the moment
# the user object was built. Every SDK still needs these attributes present by the time a
# rule is matched — that's covered by rules.feature's featureflow.date scenario, which
# supplies the attribute explicitly rather than depending on either injection point. Run
# exactly one of the two tagged scenarios below per SDK, matching its actual architecture:
#   @builder-injects-implicit-attributes  — UserBuilder#build itself sets them
#   @builder-defers-implicit-attributes   — UserBuilder#build must NOT set them (Client#evaluate does, later)
#
# @user-builder-validates-empty-id is tagged (rather than assumed universal) because at
# least one SDK's user constructor is a plain data class with no builder-side validation
# (featureflow-python-sdk's User.__init__ accepts an empty id silently) — exclude this tag
# for SDKs that don't validate rather than fake the assertion in step defs.
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

  @builder-defers-implicit-attributes
  Scenario: Test the User Builder does not inject implicit attributes at build time
    Given there is access to the User Builder module
    When the builder is initialised with the id "user"
    And the builder is given the following attributes
      | key  | value  |
      | age  | 21     |
      | type | beta   |
    And the user is built using the builder
    Then the result user should not have a attribute with key "featureflow.user.id"
    And the result user should not have a attribute with key "featureflow.date"

  @user-builder-validates-empty-id
  Scenario: Test the User Builder throws an error when no key is provided
    Given there is access to the User Builder module
    When the builder is initialised with the id ""
    Then the builder should throw an error
