# Halogen Wallet Connect Component

A reusable Halogen component for Cardano wallet connection with CIP-30 support. This library provides a drop-in wallet connection widget that handles wallet discovery, connection, and state management.

## Features

- 🔗 **CIP-30 Wallet Integration** - Connect to any CIP-30 compatible Cardano wallet
- 🎨 **Customizable UI** - Configurable buttons and asset URLs
- 🔄 **State Management** - Built-in wallet state and connection handling
- 📦 **Type-Safe** - Full PureScript type safety with Halogen
- 🛠 **Extensible** - Easy to integrate into existing Halogen applications
- 🔌 **Query Interface** - Programmatic control of wallet connection state

## Installation

Add this package to your `spago.yaml`:

```yaml
workspace:
  packageSet:
    registry: 55.0.0
  extraPackages:
    cardano-serialization-lib:
      git: https://github.com/mariusgeorgescu/purescript-cardano-serialization-lib.git
      ref: 7d6c664b125ce8c3cc441912fb8daf72294c17e7
    cip30:
      git: https://github.com/mariusgeorgescu/purescript-cip30.git
      ref: fb4b90fcca1f57edaacd6405965bf245d3504583
    cardano-capabilities:
      git: https://github.com/mariusgeorgescu/purescript-cardano-capabilities.git
      ref: main
    halogen-wallet-connect-component:
      git: https://github.com/your-username/halogen-wallet-connect-component.git
      ref: main

package:
  dependencies:
    - halogen-wallet-connect-component
    # ... your other dependencies
```

Then install:

```bash
spago install
```

## Quick Start

### 1. Import the Component

```purescript
import Components.WalletConnectComponent as WC
import Cardano.Capabilities.Wallet.MonadCIP30 (class MonadCIP30)
```

Or use the re-exported module:

```purescript
import WalletConnect.Component as WC
```

### 2. Implement MonadCIP30 in Your App Monad

The component requires your app monad to implement `MonadCIP30` from the `purescript-cardano-capabilities` library. If you're using `HalogenM`, you can leverage the built-in instance provided by that library:

```purescript
import Cardano.Capabilities.Wallet.MonadCIP30 (class MonadCIP30)
import Halogen as H

-- If using HalogenM, the instance is already provided by purescript-cardano-capabilities
-- For custom monads, implement the full interface:
instance monadCip30MyApp :: MonadCIP30 MyAppM where
  enable w exts = liftAff $ Cip30.enable w exts
  getExtensions = liftAff <<< Cip30.getExtensions
  getNetworkId = liftAff <<< Cip30.getNetworkId
  getUtxos api ma mp = liftAff $ Cip30.getUtxos api ma mp
  getCollateral api amt = liftAff $ Cip30.getCollateral api amt
  getBalance = liftAff <<< Cip30.getBalance
  getUsedAddresses api mp = liftAff $ Cip30.getUsedAddresses api mp
  getUnusedAddresses = liftAff <<< Cip30.getUnusedAddresses
  getChangeAddress = liftAff <<< Cip30.getChangeAddress
  getRewardAddresses = liftAff <<< Cip30.getRewardAddresses
  signTx api tx isPartial = liftAff $ Cip30.signTx api tx isPartial
  signData api addr payload = liftAff $ Cip30.signData api addr payload
  submitTx api tx = liftAff $ Cip30.submitTx api tx
  isEnabled = liftAff <<< Cip30.isEnabled
  getAvailableWallets = liftEffect Cip30.getAvailableWallets
  getApiVersion = liftEffect <<< Cip30.getApiVersion
  getName = liftEffect <<< Cip30.getName
  getIcon = liftEffect <<< Cip30.getIcon
  getSupportedExtensions = liftEffect <<< Cip30.getSupportedExtensions
  isWalletAvailable = liftEffect <<< Cip30.isWalletAvailable
```

### 3. Add Component to Your Halogen App

```purescript
import Components.WalletConnectComponent as WC
import Halogen as H
import Halogen.HTML as HH

type Slots = 
  ( walletConnectComponent :: WC.Slot
  -- ... other slots
  )

data Action 
  = HandleWalletConnect WC.Output
  -- ... other actions

render :: forall m. MonadAff m => MonadCIP30 m => State -> H.ComponentHTML Action Slots m
render state =
  HH.div_
    [ HH.slot WC.walletConnectProxy unit WC.component input HandleWalletConnect
    -- ... rest of your UI
    ]
  where
  input = 
    { buttons: customButtons
    , assets:
        { connectIcon: "/assets/wallet-icon.svg"
        , disconnectIcon: "/assets/disconnect-icon.svg"
        }
    }

  customButtons =
    [ { id: "home", label: "Home", iconSrc: "/assets/home.svg", classes: ["btn-secondary"] }
    , { id: "settings", label: "Settings", iconSrc: "/assets/settings.svg", classes: ["btn-primary"] }
    ]

handleAction :: forall m. MonadAff m => MonadCIP30 m => Action -> H.HalogenM State Action Slots Output m Unit
handleAction = case _ of
  HandleWalletConnect output -> case output of
    WC.WalletConnectedEvent -> do
      -- Handle wallet connection
      H.liftEffect $ log "Wallet connected!"
    WC.WalletDisconnectedEvent -> do
      -- Handle wallet disconnection  
      H.liftEffect $ log "Wallet disconnected!"
    WC.CustomButtonEvent buttonId -> do
      -- Handle custom button clicks
      case buttonId of
        "home" -> navigateToHome
        "settings" -> openSettings
        _ -> pure unit
```

## API Reference

### Component Input

```purescript
type Input = 
  { buttons :: Array ButtonConfig
  , assets :: 
      { connectIcon :: String
      , disconnectIcon :: String  
      }
  }

type ButtonConfig =
  { id :: String           -- Unique identifier
  , label :: String        -- Display text
  , iconSrc :: String      -- Icon URL
  , classes :: Array String -- CSS classes
  }
```

### Component Output

```purescript
data Output
  = WalletConnectedEvent
  | WalletDisconnectedEvent  
  | CustomButtonEvent String -- Button ID
```

### Component Queries

```purescript
data Query a
  = SetWalletApi (Maybe Api) a
  | GetWalletApi (Maybe Api -> a)
  | GetConnectedWalletInfo (Maybe ConnectedWalletInfo -> a)
  | GetAvailableWalletExtensions (Array (Tuple String String) -> a)
  | DisconnectWalletQuery a
```

**Query Usage Examples:**

```purescript
-- Set wallet API programmatically
_ <- H.query WC.walletConnectProxy unit $ H.mkTell $ WC.SetWalletApi (Just api)

-- Get current wallet API
api <- H.query WC.walletConnectProxy unit $ H.mkRequest WC.GetWalletApi

-- Get connected wallet information
walletInfo <- H.query WC.walletConnectProxy unit $ H.mkRequest WC.GetConnectedWalletInfo

-- Get available wallets
wallets <- H.query WC.walletConnectProxy unit $ H.mkRequest WC.GetAvailableWalletExtensions

-- Disconnect wallet programmatically
_ <- H.query WC.walletConnectProxy unit $ H.mkTell WC.DisconnectWalletQuery
```

### Connected Wallet Info

```purescript
type ConnectedWalletInfo =
  { connectedWalletName :: String
  , connectedWalletIcon :: String
  , connectedWalletNetwork :: String  
  , connectedWalletAddress :: String
  , connectedWalletNativeCoinBalance :: String
  }
```

## MonadCIP30 Capability

The component requires your app monad to implement `MonadCIP30`. This provides access to all CIP-30 wallet functions. If you're using `HalogenM`, an instance is already provided.

### Core CIP-30 Methods
- `enable` - Connect to a wallet with extensions
- `getBalance` - Get wallet balance (returns CBOR)
- `getUsedAddresses` - Get used addresses
- `getUnusedAddresses` - Get unused addresses
- `getChangeAddress` - Get change address
- `getRewardAddresses` - Get reward addresses
- `getNetworkId` - Get network ID (0=Preview, 1=Mainnet, 2=Preprod)
- `getUtxos` - Get UTXOs with optional filtering
- `getCollateral` - Get collateral UTXOs
- `signTx` - Sign transactions
- `signData` - Sign arbitrary data
- `submitTx` - Submit transactions

### Wallet Discovery  
- `getAvailableWallets` - List available wallet names
- `getName` - Get wallet name
- `getIcon` - Get wallet icon URL
- `isWalletAvailable` - Check if wallet is available
- `getApiVersion` - Get wallet API version
- `getSupportedExtensions` - Get supported CIP-30 extensions
- `isEnabled` - Check if wallet is currently enabled

### Helper Functions
The `purescript-cardano-capabilities` library provides convenient helper functions in `Cardano.Capabilities.Wallet.MonadCIP30`:
- `enableWallet` - Enable wallet with default CIP-30 extensions `[{ cip: 30 }]`
- `getTheAvailableWallets` - Get wallets with icons as `Array (Tuple WalletName String)`
- `getNetworkName` - Get human-readable network name ("Mainnet", "Preview", "Preprod", "Unknown")
- `getNativeCoinBalance` - Get ADA balance as `BigNum` (in lovelace)
- `getNativeCoinBalanceString` - Get ADA balance as formatted string with "₳" symbol
- `getNativeAssetsBalance` - Get native assets (non-ADA) balance
- `getUserAddresses` - Get all used addresses
- `getUserFirstAddressBech32` - Get first address in Bech32 format

## Styling

The component uses DaisyUI/Tailwind CSS classes for styling. Make sure your project includes DaisyUI or provide custom CSS for the classes used:

### Required Classes
- `btn`, `btn-primary`, `btn-secondary`
- `dropdown`, `dropdown-hover`, `dropdown-content`, `dropdown-bottom`, `dropdown-end`
- `menu`, `mask`, `mask-hexagon`
- `card`, `card-body`, `card-title`, `card-compact`
- `divider`, `divider-neutral`
- `flex`, `justify-end`, `items-center`, `gap-2`
- `text-primary`, `text-secondary`, `text-primary-content`, `text-secondary-content`
- `bg-primary`, `bg-secondary`, `bg-base-100`
- `rounded-box`, `z-40`, `min-w-40`, `min-w-64`, `w-fit`, `w-8`, `w-64`
- `font-bold`, `link`

The component automatically adjusts button colors based on connection state (primary when connected, secondary when disconnected).

## Component Behavior

### Connection Flow
1. Component initializes and checks for available wallets
2. If no wallets are available, shows a message with a link to install Lace wallet
3. If wallets are available, shows a dropdown list of wallets
4. User clicks a wallet to connect
5. Component enables the wallet and fetches connection info (name, icon, network, address, balance)
6. Connected state is displayed with wallet details in a dropdown menu
7. Custom buttons (if configured) appear in the dropdown
8. User can disconnect via the dropdown menu

### State Management
- The component maintains its own internal state for wallet connection
- External components can query or set wallet state using the Query interface
- Wallet connection/disconnection events are emitted as Output messages

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `spago build` to ensure it compiles
5. Run `npm run format` to format the code (uses `purs-tidy`)
6. Submit a pull request

## Development

### Build
```bash
spago build
```

### Format Code
```bash
npm run format
# or
purs-tidy format-in-place src/**/*.purs
```

### Clean
```bash
npm run clean
# or
rm -rf output .spago
```

## Dependencies

This library depends on:
- `halogen` - UI framework
- `cardano-capabilities` - Cardano capability type classes (provides `MonadCIP30`)
- `cip30` - CIP-30 wallet interface bindings
- `cardano-serialization-lib` - Cardano serialization library
- Standard PureScript packages (arrays, effect, maybe, prelude, etc.)

## License

MIT License - see [LICENSE](./LICENSE) file for details.

## Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/your-username/halogen-wallet-connect-component/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/your-username/halogen-wallet-connect-component/discussions)
- 📖 **Documentation**: This README and inline code comments

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for detailed version history.

### v1.1.0
- **BREAKING**: Replaced local `Capabilities.MonadCIP30` with external `purescript-cardano-capabilities` library
- Updated imports to use `Cardano.Capabilities.Wallet.MonadCIP30`
- Added `cardano-capabilities` dependency

### v1.0.2
- Updated README with accurate documentation

### v1.0.1
- Added `DisconnectWalletQuery` query for programmatic wallet disconnection

### v1.0.0
- Initial release
- CIP-30 wallet connection support
- Configurable UI and assets
- Full PureScript/Halogen integration
- Query interface for wallet API management
