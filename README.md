# Halogen Wallet Connect Component

A reusable Halogen component for Cardano wallet connection with CIP-30 support. This library provides a drop-in wallet connection widget that handles wallet discovery, connection, and state management.

## Features

- 🔗 **CIP-30 Wallet Integration** - Connect to any CIP-30 compatible Cardano wallet
- 🎨 **Customizable UI** - Configurable buttons and asset URLs
- 🔄 **State Management** - Built-in wallet state and connection handling
- 📦 **Type-Safe** - Full PureScript type safety with Halogen
- 🛠 **Extensible** - Easy to integrate into existing Halogen applications

## Installation

Add this package to your `spago.yaml`:

```yaml
workspace:
  extraPackages:
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
import WalletConnect.Component as WalletConnect
```

### 2. Implement MonadCIP30 in Your App Monad

```purescript
import Capabilities.MonadCIP30 (class MonadCIP30)
import Cardano.Wallet.Cip30 as Cip30

instance monadCip30MyApp :: MonadCIP30 MyAppM where
  enable w exts = liftAff $ Cip30.enable w exts
  getExtensions = liftAff <<< Cip30.getExtensions
  getNetworkId = liftAff <<< Cip30.getNetworkId
  getBalance = liftAff <<< Cip30.getBalance
  getUsedAddresses api mp = liftAff $ Cip30.getUsedAddresses api mp
  getName = liftEffect <<< Cip30.getName
  getIcon = liftEffect <<< Cip30.getIcon
  isWalletAvailable = liftEffect <<< Cip30.isWalletAvailable
  getAvailableWallets = liftEffect Cip30.getAvailableWallets
  -- ... implement other methods as needed
```

### 3. Add Component to Your Halogen App

```purescript
import WalletConnect.Component as WC

type Slots = 
  ( walletConnect :: WC.Slot
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

The component requires your app monad to implement `MonadCIP30`. This provides access to all CIP-30 wallet functions:

### Core Methods
- `enable` - Connect to a wallet
- `getBalance` - Get wallet balance
- `getUsedAddresses` - Get used addresses
- `getNetworkId` - Get network ID
- `signTx` - Sign transactions
- `submitTx` - Submit transactions

### Wallet Discovery  
- `getAvailableWallets` - List available wallets
- `getName` - Get wallet name
- `getIcon` - Get wallet icon
- `isWalletAvailable` - Check if wallet is available

### Helper Functions
The library also provides convenient helper functions:
- `enableWallet` - Enable with default CIP-30 extensions
- `getTheAvailableWallets` - Get wallets with icons
- `getNetworkName` - Get human-readable network name
- `getNativeCoinBalance` - Get ADA balance as BigNum
- `getUserFirstAddressBech32` - Get first address in Bech32 format

## Styling

The component uses DaisyUI classes for styling. Make sure your project includes DaisyUI or provide custom CSS for the classes used:

- `btn`, `btn-primary`, `btn-secondary`
- `dropdown`, `dropdown-hover`, `dropdown-content`
- `menu`, `mask`, `mask-hexagon`
- `card`, `card-body`, `card-title`
- `divider`

## Example Projects

See the [examples](./examples) directory for complete integration examples:
- Basic wallet connection
- Transaction signing
- Multi-wallet support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `spago build` to ensure it compiles
5. Run `npm run format` to format the code
6. Submit a pull request

## License

MIT License - see [LICENSE](./LICENSE) file for details.

## Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/your-username/halogen-wallet-connect-component/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/your-username/halogen-wallet-connect-component/discussions)
- 📖 **Documentation**: This README and inline code comments

## Changelog

### v1.0.0
- Initial release
- CIP-30 wallet connection support
- Configurable UI and assets
- Full TypeScript/PureScript integration
