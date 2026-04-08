-- | FFI bindings and types for UTXOS Wallet-as-a-Service SDK.
-- | Provides social-login wallets and fiat on-ramp via @utxos/sdk.
module Utxos.Sdk
  ( IFetcher
  , UtxosConfig
  , UtxosWallet
  , utxosEnable
  , getCardanoApi
  , getUtxosUserAvatarUrl
  , getUtxosUserName
  , utxosOnramp
  ) where

import Prelude
import Cardano.Wallet.Cip30 (Api)
import Control.Promise (Promise, toAffE)
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toMaybe, toNullable)
import Effect (Effect)
import Effect.Aff (Aff)

-- | Opaque Mesh IFetcher / ISubmitter interface (BlockfrostProvider, MaestroProvider, etc.).
foreign import data IFetcher :: Type

-- | Configuration for UTXOS Wallet-as-a-Service integration.
type UtxosConfig =
  { projectId :: String -- ^ UTXOS project ID from dashboard
  , networkId :: Int -- ^ 0 = preprod, 1 = mainnet
  , walletIcon :: String -- ^ Icon URL for display in wallet list
  , walletLabel :: String -- ^ Display name, e.g. "Social Login"
  , fetcher :: Maybe IFetcher -- ^ Mesh IFetcher for chain data (balance, UTXOs)
  , submitter :: Maybe IFetcher -- ^ Mesh ISubmitter for tx submission (often same object)
  }

-- | Opaque handle to a connected UTXOS wallet. Needed for on-ramp access.
foreign import data UtxosWallet :: Type

foreign import _utxosEnable :: String -> Int -> Nullable IFetcher -> Nullable IFetcher -> Effect (Promise UtxosWallet)
foreign import _getCardanoApi :: UtxosWallet -> Api
foreign import _utxosOnramp :: UtxosWallet -> { chain :: String, cryptoCurrency :: String } -> Effect (Promise Unit)
foreign import _getUtxosUserAvatarUrl :: UtxosWallet -> Nullable String
foreign import _getUtxosUserName :: UtxosWallet -> Nullable String

-- | Enable a UTXOS wallet via social login. Opens authentication popup.
utxosEnable :: UtxosConfig -> Aff UtxosWallet
utxosEnable cfg = toAffE (_utxosEnable cfg.projectId cfg.networkId (toNullable cfg.fetcher) (toNullable cfg.submitter))

-- | Extract the CIP-30 compatible Api from a UTXOS wallet (synchronous).
getCardanoApi :: UtxosWallet -> Api
getCardanoApi = _getCardanoApi

-- | Get the social login avatar URL (Google/Discord/Apple/X profile picture), if available.
getUtxosUserAvatarUrl :: UtxosWallet -> Maybe String
getUtxosUserAvatarUrl = toMaybe <<< _getUtxosUserAvatarUrl

-- | Get the social login username, if available.
getUtxosUserName :: UtxosWallet -> Maybe String
getUtxosUserName = toMaybe <<< _getUtxosUserName

-- | Open fiat on-ramp (Mercuryo) for ADA purchase.
utxosOnramp :: UtxosWallet -> Aff Unit
utxosOnramp w = toAffE (_utxosOnramp w { chain: "cardano", cryptoCurrency: "ADA" })
