# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-04-08

### Added
- On-ramp ("Buy ADA") now available for extension-connected wallets via configurable URL with `{address}` placeholder
- `onrampIcon :: String` field on `assets` in `Input` — icon for the on-ramp button (consistent with `connectIcon`/`disconnectIcon`)
- `onrampUrl :: Maybe String` field on `Input` — on-ramp URL template for extension wallets (e.g. `"https://exchange.mercuryo.io/?widget_id=XXX&currency=ADA&address={address}"`)
- `Utils.js` FFI with `openUrl` for opening URLs in a new browser tab

### Changed
- **BREAKING**: `onrampIcon :: String` added to `assets` record in `Input`
- **BREAKING**: `onrampUrl :: Maybe String` added to `Input` (pass `Nothing` to preserve existing behavior)
- On-ramp button moved from actions area to wallet info section in both standalone and unified render modes
- On-ramp button now displays an icon (matching the `mask mask-hexagon` pattern used by other buttons)

## [2.1.0] - 2026-04-08

### Added
- `IFetcher` opaque type for Mesh chain data providers (BlockfrostProvider, MaestroProvider, etc.)
- `fetcher :: Maybe IFetcher` and `submitter :: Maybe IFetcher` fields on `UtxosConfig` — passed through to `Web3Wallet.enable()` for chain data access (balance, UTXOs, signing)
- Workaround for `@utxos/sdk@0.2.0` bug: `initCardanoWallet()` drops the fetcher before creating `MeshCardanoHeadlessWallet`; the FFI now post-patches `wallet.cardano.fetcher` after `enable()` returns
- `getUtxosUserAvatarUrl` — extract social login avatar URL from the UTXOS user profile (Google, Discord, Apple, X)
- `getUtxosUserName` — extract social login username from the UTXOS user profile

### Changed
- `ConnectUtxosWallet` handler now uses the social login avatar as `connectedWalletIcon` and username as `connectedWalletName` (falls back to `walletIcon`/`walletLabel` from config)
- Unified trigger shows the wallet icon (social avatar or extension icon) instead of a "?" placeholder when no profile is active
- Added `nullable` PureScript dependency

## [2.0.0] - 2026-04-08

### Added
- UTXOS Wallet-as-a-Service integration (social login wallets via Google, Discord, Apple, X)
- Fiat On-Ramp (Buy ADA) support via UTXOS/Mercuryo
- `Utxos.Sdk` module with FFI bindings (`UtxosConfig`, `UtxosWallet`, `utxosEnable`, `getCardanoApi`, `utxosOnramp`)
- `WalletConnection` ADT (`NotConnected | ViaExtension | ViaUtxos`) for type-safe connection source tracking
- `FiatOnrampInitiatedEvent` output event
- `RefreshWalletInfoQuery` query to re-fetch balance, address, and network from the connected wallet
- `@utxos/sdk` as optional npm peer dependency (only needed when using UTXOS features)
- `aff-promise` and `aff` as explicit PureScript dependencies

### Changed
- **BREAKING**: Added `utxosConfig :: Maybe UtxosConfig` to `Input` (pass `Nothing` to preserve existing behavior)
- Bumped version to 2.0.0
- "No wallet installed" message now only shows when both browser extensions and UTXOS config are unavailable

## [1.1.1] - 2024-12-19

### Changed
- Fixed file path structure: moved `HTML/RenderUtils.purs` to `Components/HTML/RenderUtils.purs` to match module name
- Updated package.json main entry point to point directly to `Components/WalletConnectComponent.purs`

### Removed
- Removed redundant `WalletConnect/Component.purs` re-export module
- Removed unused `trimQuotes` function from `Utils.purs`

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
