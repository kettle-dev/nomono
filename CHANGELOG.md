# Changelog

[![SemVer 2.0.0][📌semver-img]][📌semver] [![Keep-A-Changelog 1.0.0][📗keep-changelog-img]][📗keep-changelog]

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][📗keep-changelog],
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html),
and [yes][📌major-versions-not-sacred], platform and engine support are part of the [public API][📌semver-breaking].
Please file a bug if you notice a violation of semantic versioning.

[📌semver]: https://semver.org/spec/v2.0.0.html
[📌semver-img]: https://img.shields.io/badge/semver-2.0.0-FFDD67.svg?style=flat
[📌semver-breaking]: https://github.com/semver/semver/issues/716#issuecomment-869336139
[📌major-versions-not-sacred]: https://tom.preston-werner.com/2022/05/23/major-version-numbers-are-not-sacred.html
[📗keep-changelog]: https://keepachangelog.com/en/1.0.0/
[📗keep-changelog-img]: https://img.shields.io/badge/keep--a--changelog-1.0.0-FFDD67.svg?style=flat

## [Unreleased]

### Added

### Changed

- kettle-jem-template-20260801-001 - Generated README gem dashboard links now
  use ClickGems instead of BestGems.

### Deprecated

### Removed

### Fixed

- kettle-jem-template-20260801-002 - Generated RSpec helpers now normalize
  managed configuration block bindings structurally, preventing mixed block
  parameter names from producing invalid configuration after a merge.
- kettle-jem-template-20260801-003 - Generated project metadata and
  documentation now normalize configured underscore hostnames to valid
  hyphenated hostnames.
- kettle-jem-template-20260801-004 - Generated organization README logos now
  use GitHub's stable organization avatar endpoint instead of assuming a
  matching Galtzo-hosted asset exists.

### Security

## [1.1.2] - 2026-07-31

- TAG: [v1.1.2][1.1.2t]
- COVERAGE: 97.56% -- 120/123 lines in 7 files
- BRANCH COVERAGE: 86.67% -- 39/45 branches in 7 files
- 25.00% documented

### Added

- kettle-jem-template-20260729-005 - Gemspec metadata now publishes this
  project's RubyForum tag as `mailing_list_uri`, and support docs link to the
  tagged RubyForum community alongside Discord.

### Fixed

- kettle-jem-template-20260728-003 - Generated dep-heads workflows now run
  TruffleRuby jobs with current RubyGems and Bundler, avoiding setup failures
  before the test suite starts.
- kettle-jem-template-20260728-004 - Generated dep-heads workflows now use the
  setup-ruby Bundler install path for direct appraisal Gemfiles, avoiding rv
  lockfile parser failures on Git and path dependencies.
- kettle-jem-template-20260728-005 - VersionGem bootstrap now creates the
  missing canonical version spec when a project only has shim namespace version
  specs.
- kettle-jem-template-20260729-001 - Generated JRuby 9.4 workflows now use the
  legacy manual bundle install path, avoiding setup-time Bundler full-index
  failures against `gem.coop`.
- kettle-jem-template-20260729-002 - VersionGem bootstrap now preserves
  and templates dedicated `version_gem.rb` entrypoints even when the gemspec
  dependency is intentionally omitted, and generated anonymous-loader specs
  cover both `version.rb` and `version_gem.rb`.
- kettle-jem-template-20260729-003 - Old-Ruby gems below the VersionGem runtime
  floor now get managed minimal `version.rb` files and anonymous-loader version
  specs without adding `version_gem`.
- kettle-jem-template-20260730-001 - Gemspec package file enumeration now runs
  relative to the gemspec directory, so release package contents stay correct
  even when the gemspec is loaded from another working directory.

## [1.1.1] - 2026-07-28

- TAG: [v1.1.1][1.1.1t]
- COVERAGE: 94.31% -- 116/123 lines in 7 files
- BRANCH COVERAGE: 86.67% -- 39/45 branches in 7 files
- 25.00% documented

### Added

- kettle-jem-template-20260726-001 - Projects now include YARD lint
  configuration and documentation dependencies so documentation issues fail
  before generated docs are refreshed.

- kettle-jem-template-20260727-001 - Spec harness documentation now lists the
  RSpec helpers provided by `kettle-test`.

### Changed

- kettle-jem-template-20260725-001 - Release pull request branches beginning
  with `feature/release` now run JRuby and TruffleRuby workflows.
- kettle-jem-template-20260725-002 - Version specs now use `anonymous_loader` to
  cover `version.rb` without redefining constants, or are removed when version
  specs are not managed for the project.

- kettle-jem-template-20260728-001 - Generated Ruby workflows now use clearer
  setup-ruby-flash planning and can prepare appraisal-only jobs without
  installing the main Gemfile bundle.

### Fixed

- kettle-jem-template-20260726-002 - Generated version files now document their
  version namespace and constants, reducing warning-only YARD lint output.

- kettle-jem-template-20260726-003 - Coverage upload steps now treat Coveralls,
  QLTY, and Codecov as optional, so provider outages do not fail CI when local
  coverage thresholds still pass.
- kettle-jem-template-20260728-002 - Generated RuboCop configs now ignore the
  same `gemfiles/vendor/bundle` tree as `.gitignore`, so vendored dependency
  installs are not reported as project lint debt.

## [1.1.0] - 2026-07-22

- TAG: [v1.1.0][1.1.0t]
- COVERAGE: 97.56% -- 120/123 lines in 7 files
- BRANCH COVERAGE: 86.67% -- 39/45 branches in 7 files
- 12.50% documented

### Added

- Added opt-in path alias normalization so local sibling paths can be rewritten
  to a configured canonical spelling before Bundler writes them to lockfiles.

### Changed

- kettle-jem-template-20260716-001 - Shim gemspec manifests now include
  `LICENSE.md` instead of nonexistent `LICENSE.txt`.
- kettle-jem-template-20260716-002 - Generated gemspec manifests now ship fewer
  repository-only files by default to reduce downstream distro packaging churn.

- kettle-jem-template-20260720-001 - Generated READMEs can now render
  template-managed corporate sponsor logos from project or family config.
- kettle-jem-template-20260720-002 - Generated development Gemfiles now use the
  released `tree_sitter_language_pack` gem 1.13.3 or newer by default.
- kettle-jem-template-20260720-003 - Generated StructuredMerge Git diff driver
  config now uses the installed `smorg-rb` Ruby driver name.
- kettle-jem-template-20260720-004 - Generated multi-engine workflow files now
  omit JRuby and TruffleRuby jobs when project config declares MRI-only engines.
- kettle-jem-template-20260720-005 - Generated README Support & Community rows
  now include a RubyForum help badge.

### Fixed

- Documented why `nomono` uses an explicit Gemfile loader instead of the
  Bundler plugin DSL or RubyGems plugin autoload hooks, and simplified
  `nomono`'s own local Gemfiles to load the local Bundler integration directly.

- Addressed review feedback by keeping split license detail links pointed at
  the source repository, keeping `tree_sitter_language_pack` in the templating
  dependency path only, and regenerating YARD documentation.

- Local modular Gemfiles now load `nomono/bundler` with the normal Bundler
  require path so RuboCop Gradual style checks pass under appraisal bundles.

## [1.0.8] - 2026-07-13

- TAG: [v1.0.8][1.0.8t]
- COVERAGE: 100.00% -- 89/89 lines in 7 files
- BRANCH COVERAGE: 100.00% -- 28/28 branches in 7 files
- 12.50% documented

## [1.0.7] - 2026-07-01

- TAG: [v1.0.7][1.0.7t]
- COVERAGE: 100.00% -- 88/88 lines in 6 files
- BRANCH COVERAGE: 100.00% -- 28/28 branches in 6 files
- 12.50% documented

### Fixed

- Package configured license files in gem release file lists.

## [1.0.6] - 2026-06-22

- TAG: [v1.0.6][1.0.6t]
- COVERAGE: 99.01% -- 100/101 lines in 6 files
- BRANCH COVERAGE: 96.67% -- 29/30 branches in 6 files
- 8.70% documented

### Fixed

- Removed `version_gem` from nomono's default load path, allowing Gemfiles
  generated by `kettle-jem` to load `nomono/bundler` directly while Bundler is
  still evaluating local sibling-gem overrides.
- Split the runtime and Bundler entry points so `require "nomono"` loads the
  resolver API without mutating `Bundler::Dsl`, while `require "nomono/bundler"`
  remains the explicit Gemfile integration hook.

## [1.0.5] - 2026-06-21

- TAG: [v1.0.5][1.0.5t]
- COVERAGE: 97.73% -- 86/88 lines in 5 files
- BRANCH COVERAGE: 100.00% -- 28/28 branches in 5 files
- 12.50% documented

### Added

- Added support for JRuby 10.1 and TruffleRuby 34.0.

### Changed

- Retemplated project metadata and CI/development automation with `kettle-jem` v7.0.0.

### Fixed

- Corrected OpenCollective funding metadata to use the `kettle-dev` collective.
- Updated the default local workspace root from `$HOME/src/kettle-dev` to
  `$HOME/src/my`.

## [1.0.4] - 2026-06-14

- TAG: [v1.0.4][1.0.4t]
- COVERAGE: 100.00% -- 86/86 lines in 4 files
- BRANCH COVERAGE: 100.00% -- 28/28 branches in 4 files
- 12.50% documented

### Changed

- Retemplated with the current kettle-jem template set, refreshing generated
  README metadata, the templating dependency floor, and the development lockfile.

### Fixed

- Removed a duplicate RBS `Nomono::VERSION` declaration and strengthened the
  style workflow RBS check to load the signature environment.

## [1.0.3] - 2026-06-10

- TAG: [v1.0.3][1.0.3t]
- COVERAGE: 100.00% -- 86/86 lines in 4 files
- BRANCH COVERAGE: 100.00% -- 28/28 branches in 4 files
- 12.50% documented

### Changed

- Development tooling now resolves `kettle-dev` 2.2.3, `kettle-test` 2.0.5,
  `kettle-soup-cover` 2.0.2, and `yard-fence` 0.9.3 or newer.

### Fixed

- Updated generated project metadata links to use the migrated `kettle-dev`
  GitHub organization.

- Corrected misspelled contact metadata to use `galtzo.com`.

## [1.0.2] - 2026-05-31

- TAG: [v1.0.2][1.0.2t]
- COVERAGE: 100.00% -- 86/86 lines in 4 files
- BRANCH COVERAGE: 100.00% -- 28/28 branches in 4 files
- 12.50% documented

### Added

- Added StructuredMerge git diff driver configuration and the incident response
  plan from the current kettle-jem template.

### Changed

- Retemplated with the current kettle-jem template set, including the
  `.structuredmerge/kettle-jem.yml` config migration, README logo and
  templating attribution refresh, current modular Gemfile dependencies, and the
  `kettle-dev` 2.0.6 development dependency floor.

### Fixed

- Fixed generated documentation URLs that incorrectly pointed at a monorepo
  `gems/nomono` path.
- Made the debug-output resolver spec tolerant of Ruby implementation
  differences in `Hash#inspect` spacing.

## [1.0.1] - 2026-05-27

- TAG: [v1.0.1][1.0.1t]
- COVERAGE: 100.00% -- 86/86 lines in 4 files
- BRANCH COVERAGE: 100.00% -- 28/28 branches in 4 files
- 12.50% documented

### Added

- Improved documentation of ENV variables and overrides in README.md

### Changed

- Retemplated with the current kettle-jem template set.

### Fixed

- (dev) Updated the development dependency floor to `kettle-dev` 2.0.1 so the
  templated `yard` rake task installs the expected yard-timekeeper cleanup.
- (dev) Routed `bin/yard` through `bin/rake yard` so direct documentation runs use the
  same rake-installed documentation plugin hooks.
- (dev) Restored templated Rake task loading so `bin/rake` runs the expected
  development task set instead of only the default stub.
- (dev) Restored full line and branch coverage for the public resolver and installer
  behavior.

## [1.0.0] - 2026-03-26

- TAG: [v1.0.0][1.0.0t]
- 12.50% documented

[Unreleased]: https://github.com/kettle-dev/nomono/compare/v1.1.2...HEAD
[1.1.2]: https://github.com/kettle-dev/nomono/compare/v1.1.1...v1.1.2
[1.1.2t]: https://github.com/kettle-dev/nomono/releases/tag/v1.1.2
[1.1.1]: https://github.com/kettle-dev/nomono/compare/v1.1.0...v1.1.1
[1.1.1t]: https://github.com/kettle-dev/nomono/releases/tag/v1.1.1
[1.1.0]: https://github.com/kettle-dev/nomono/compare/v1.0.9...v1.1.0
[1.1.0t]: https://github.com/kettle-dev/nomono/releases/tag/v1.1.0
[1.0.9]: https://github.com/kettle-dev/nomono/compare/v1.0.8...v1.0.9
[1.0.9t]: https://github.com/kettle-dev/nomono/releases/tag/v1.0.9
[1.0.8]: https://github.com/kettle-dev/nomono/compare/v1.0.7...v1.0.8
[1.0.8t]: https://github.com/kettle-dev/nomono/releases/tag/v1.0.8
[1.0.7]: https://github.com/kettle-dev/nomono/compare/v1.0.6...v1.0.7
[1.0.7t]: https://github.com/kettle-dev/nomono/releases/tag/v1.0.7
[1.0.6]: https://github.com/kettle-dev/nomono/compare/v1.0.5...v1.0.6
[1.0.6t]: https://github.com/kettle-dev/nomono/releases/tag/v1.0.6
[1.0.5]: https://github.com/kettle-dev/nomono/compare/v1.0.4...v1.0.5
[1.0.5t]: https://github.com/kettle-dev/nomono/releases/tag/v1.0.5
[1.0.4]: https://github.com/kettle-dev/nomono/compare/v1.0.3...v1.0.4
[1.0.4t]: https://github.com/kettle-dev/nomono/releases/tag/v1.0.4
[1.0.3]: https://github.com/kettle-dev/nomono/compare/v1.0.2...v1.0.3
[1.0.3t]: https://github.com/kettle-dev/nomono/releases/tag/v1.0.3
[1.0.2]: https://github.com/kettle-dev/nomono/compare/v1.0.1...v1.0.2
[1.0.2t]: https://github.com/kettle-dev/nomono/releases/tag/v1.0.2
[1.0.1]: https://github.com/kettle-dev/nomono/compare/v1.0.0...v1.0.1
[1.0.1t]: https://github.com/kettle-dev/nomono/releases/tag/v1.0.1
[1.0.0]: https://github.com/kettle-dev/nomono/compare/3080fe8ceff657265445e8b4936aa2a90faa37f9...v1.0.0
[1.0.0t]: https://github.com/kettle-dev/nomono/tags/v1.0.0
