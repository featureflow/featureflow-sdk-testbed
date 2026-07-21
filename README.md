# featureflow-sdk-testbed

Shared Gherkin scenarios that every Featureflow SDK's local (no-server) evaluation logic
must satisfy: variant bucketing (SHA-1 hash → percentage split), rule/audience/condition
matching, and user-attribute building. One shared contract,
consumed by each SDK repo, with language-specific step definitions living in that SDK's
own repo.

## Layout

```
gherkin/
  bucketing.feature          # SHA-1 hash -> variant-value -> split-key algorithm
  rules.feature              # rule/audience matching, variant-split walking
  conditions.feature         # individual condition operators (equals, contains, before, ...)
  user_builder.feature       # building a user with id + attributes
  feature_evaluation.feature # end-to-end: disabled/enabled feature -> variant
  json_value.feature         # jsonValue() variant payloads (JS-family only, see tag below)
```

## Tags

- `@builder-injects-implicit-attributes` — only for SDKs whose `UserBuilder`/equivalent
  injects `featureflow.user.id`/`featureflow.date`/`featureflow.hourofday` at *build*
  time. SDKs that inject at *evaluate* time instead (e.g. Ruby, Go — so date/hour rules
  match "now" rather than build time) should exclude this tag.
- `@json-value` — `jsonValue()`-style JSON config payloads on variants. Currently only
  implemented by the JS-family SDKs (`featureflow-javascript-sdk`,
  `react-featureflow-client`, `featureflow-react-native`). SDKs without an equivalent
  should exclude this tag rather than skip the whole file.

## Consuming this repo

Each SDK repo pulls this in as a **git submodule** (currently a local path — no GitHub
remote yet) and owns only its own step definitions, mapping these Gherkin phrases to
calls against its internal evaluation helpers (the equivalent of `EvaluateHelpers`/
`Conditions` in the server SDKs). Point your test runner's feature-file path at this
submodule's `gherkin/` directory instead of (or in addition to) any local copies, and
delete the local copies once that's confirmed working — the scenario content should
live here, not be duplicated per repo.

This repo currently only covers **local, no-server** evaluation logic. A live-server
harness is planned as a later phase and will live under a `harness/` directory here once built.
