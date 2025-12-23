# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2024-12-19

### Changed
- **BREAKING**: Replaced local `Capabilities.MonadCIP30` module with external `purescript-cardano-capabilities` library
- Updated imports to use `Cardano.Capabilities.Wallet.MonadCIP30` from external library
- Removed local capabilities implementation in favor of shared library

### Removed
- Removed `src/Capabilities/MonadCIP30.purs` module (now provided by `purescript-cardano-capabilities`)

## [1.0.2] - 2024-12-19

### Changed
- Updated README with accurate module paths and import examples
- Enhanced API documentation with complete MonadCIP30 interface
- Added query usage examples and component behavior documentation
- Improved styling documentation with complete class list
- Fixed installation instructions to include required dependencies

## [1.0.1] - 2024-12-19

### Added
- Added `DisconnectWalletQuery` query to allow external components to programmatically trigger wallet disconnection

## [1.0.0] - Initial Release

### Added
- Initial release of the Halogen Cardano Wallet Connect Component
- Support for CIP-30 wallet connections
- Custom button configuration
- Wallet connection/disconnection events
- Query interface for wallet API management
