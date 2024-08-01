# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased] - 

### Removed
- Remove `Dude::Store::Commands` mixin
- Remove `Dude::Store::Transaction#get` abstract method

### Changed
- Change `Dude::Redis::Transaction` to a `struct`
- Change `Dude::Memory::Transaction` to a `struct`

## [1.0.0] - 2024-07-22

### Added
- Add `Dude::Redis::Key#namespace` getter

### Changed
- Convert `abstract class`es into `modules`

### Fixed
- Fix namespace not set in `Dude::Redis.new` overloads

## [0.7.0] - 2024-07-08

### Added
- Add `Dude::Redis#client` getter
- Add `Dude::Memory#data` getter

## [0.6.0] - 2024-07-08

### Added
- Allow skipping cache by setting `Dude.settings.store` to `nil`

### Changed
- Move memory store to the default shard directory

## [0.5.0] - 2024-07-06

### Added
- Add support for custom storage backends
- Add memory storage backend

## [0.4.0] - 2023-11-29

### Changed
- Upgrade `jgaskins/redis` shard to v0.8

## [0.3.0] - 2023-09-30

### Changed
- Add `redis` parameter to non-fetch query methods

### Removed
- Remove `.redis_pool_size` setting

## [0.2.0] - 2023-06-01

### Changed
- Upgrade `jgaskins/redis` shard to v0.7

## [0.1.0] - 2022-12-10

### Added
- Initial release
