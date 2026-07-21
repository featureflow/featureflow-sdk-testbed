# Changelog

## Unreleased

- Initial extraction of `bucketing.feature`, `rules.feature`, `conditions.feature`,
  `user_builder.feature` from `featureflow-node-sdk` (the most complete/canonical
  existing set after Phase 0 aligned `featureflow-ruby-sdk` and `featureflow-go-sdk`
  to the same wording).
- Promoted `featureEvaluation.feature` (renamed `feature_evaluation.feature`) to
  canonical — universal end-to-end disabled/enabled → variant behavior.
- Promoted `jsonValue.feature` (renamed `json_value.feature`), tagged `@json-value`
  since it's currently JS-family-only, not yet a universal SDK contract.
- Split `user_builder.feature`'s implicit-attribute-injection scenario into its own
  `@builder-injects-implicit-attributes`-tagged scenario, since whether `UserBuilder`
  injects `featureflow.user.id`/`featureflow.date` at build time vs. evaluate time is
  a legitimate per-SDK architecture choice, not something every SDK must do the same
  way.
