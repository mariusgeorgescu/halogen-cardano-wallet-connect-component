-- | FFI bindings and types for UTXOS Wallet-as-a-Service SDK.
-- | Provides social-login wallets and fiat on-ramp via @utxos/sdk.
module Utxos.Sdk
  ( UtxosConfig
  , UtxosWallet
  , utxosEnable
  , getCardanoApi
  , utxosOnramp
  ) where

import Prelude
import Cardano.Wallet.Cip30 (Api)
import Control.Promise (Promise, toAffE)
import Effect (Effect)
import Effect.Aff (Aff)

-- | Configuration for UTXOS Wallet-as-a-Service integration.
type UtxosConfig =
  { projectId :: String -- ^ UTXOS project ID from dashboard
  , networkId :: Int -- ^ 0 = preprod, 1 = mainnet
  , walletIcon :: String -- ^ Icon URL for display in wallet list
  , walletLabel :: String -- ^ Display name, e.g. "Social Login"
  }

-- | Opaque handle to a connected UTXOS wallet. Needed for on-ramp access.
foreign import data UtxosWallet :: Type

foreign import _utxosEnable :: String -> Int -> Effect (Promise UtxosWallet)
foreign import _getCardanoApi :: UtxosWallet -> Api
foreign import _utxosOnramp :: UtxosWallet -> { chain :: String, cryptoCurrency :: String } -> Effect (Promise Unit)

-- | Enable a UTXOS wallet via social login. Opens authentication popup.
utxosEnable :: UtxosConfig -> Aff UtxosWallet
utxosEnable cfg = toAffE (_utxosEnable cfg.projectId cfg.networkId)

-- | Extract the CIP-30 compatible Api from a UTXOS wallet (synchronous).
getCardanoApi :: UtxosWallet -> Api
getCardanoApi = _getCardanoApi

-- | Open fiat on-ramp (Mercuryo) for ADA purchase.
utxosOnramp :: UtxosWallet -> Aff Unit
utxosOnramp w = toAffE (_utxosOnramp w { chain: "cardano", cryptoCurrency: "ADA" })
