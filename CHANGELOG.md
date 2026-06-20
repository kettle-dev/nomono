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

- Added support for JRuby 10.1 and TruffleRuby 34.0.

### Changed

- Retemplated project metadata and CI/development automation with `kettle-jem` v7.0.0.

### Deprecated

### Removed

### Fixed

### Security

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

[Unreleased]: https://github.com/kettle-dev/nomono/compare/v1.0.4...HEAD
[1.0.4]: https://github.com/kettle-dev/nomono/compare/v1.0.3...v1.0.4
[1.0.4t]: https://github.com/kettle-dev/nomono/releases/tag/v1.0.4
[1.0.3]: https://github.com/kettle-dev/nomono/compare/v1.0.2...v1.0.3
[1.0.3t]: https://github.com/kettle-dev/nomono/releases/tag/v1.0.3
[1.0.2]: https://github.com/kettle-rb/nomono/compare/v1.0.1...v1.0.2
[1.0.2t]: https://github.com/kettle-rb/nomono/releases/tag/v1.0.2
[1.0.1]: https://github.com/kettle-rb/nomono/compare/v1.0.0...v1.0.1
[1.0.1t]: https://github.com/kettle-rb/nomono/releases/tag/v1.0.1
[1.0.0]: https://github.com/kettle-rb/nomono/compare/3080fe8ceff657265445e8b4936aa2a90faa37f9...v1.0.0
[1.0.0t]: https://github.com/kettle-rb/nomono/tags/v1.0.0
