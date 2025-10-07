module Capabilities.MonadCIP30 where

import Prelude
import Cardano.Wallet.Cip30 (Api, Bytes, Cbor, DataSignature, Extension, NetworkId, Paginate, WalletName)
import Cardano.Wallet.Cip30 as Cip30
import Csl as Csl
import Data.Array (zip, (!!))
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.Traversable (sequence)
import Data.Tuple (Tuple)
import Effect.Aff.Class (class MonadAff)
import Halogen (HalogenM)
import Halogen as H

class
  Monad m <= MonadCIP30 m where
  -- CIP-30 functions
  enable :: WalletName -> Array Extension -> m Api
  getExtensions :: Api -> m (Array Extension)
  getNetworkId :: Api -> m NetworkId
  getUtxos :: Api -> Maybe Cbor -> Maybe Paginate -> m (Maybe (Array Cbor))
  getCollateral :: Api -> Cbor -> m (Maybe (Array Cbor))
  getBalance :: Api -> m Cbor
  getUsedAddresses :: Api -> Maybe Paginate -> m (Array Cbor)
  getUnusedAddresses :: Api -> m (Array Cbor)
  getChangeAddress :: Api -> m Cbor
  getRewardAddresses :: Api -> m (Array Cbor)
  signTx :: Api -> Cbor -> Boolean -> m Cbor
  signData :: Api -> Cbor -> Bytes -> m DataSignature
  submitTx :: Api -> Cbor -> m String
  isEnabled :: WalletName -> m Boolean
  getAvailableWallets :: m (Array WalletName)
  getApiVersion :: WalletName -> m String
  getName :: WalletName -> m String
  getIcon :: WalletName -> m String
  getSupportedExtensions :: WalletName -> m (Array Extension)
  isWalletAvailable :: WalletName -> m Boolean

-- | Lift a MonadCIP30 into HalogenM so components can call without manual lift
instance monadCip30HalogenM :: MonadAff m => MonadCIP30 (HalogenM st act slots msg m) where
  enable w exts = H.liftAff $ Cip30.enable w exts
  getExtensions = H.liftAff <<< Cip30.getExtensions
  getNetworkId = H.liftAff <<< Cip30.getNetworkId
  getUtxos api ma mp = H.liftAff $ Cip30.getUtxos api ma mp
  getCollateral api amt = H.liftAff $ Cip30.getCollateral api amt
  getBalance = H.liftAff <<< Cip30.getBalance
  getUsedAddresses api mp = H.liftAff $ Cip30.getUsedAddresses api mp
  getUnusedAddresses = H.liftAff <<< Cip30.getUnusedAddresses
  getChangeAddress = H.liftAff <<< Cip30.getChangeAddress
  getRewardAddresses = H.liftAff <<< Cip30.getRewardAddresses
  signTx api tx isPartial = H.liftAff $ Cip30.signTx api tx isPartial
  signData api addr payload = H.liftAff $ Cip30.signData api addr payload
  submitTx api tx = H.liftAff $ Cip30.submitTx api tx
  isEnabled = H.liftAff <<< Cip30.isEnabled
  getAvailableWallets = H.liftEffect $ Cip30.getAvailableWallets
  getApiVersion = H.liftEffect <<< Cip30.getApiVersion
  getName = H.liftEffect <<< Cip30.getName
  getIcon = H.liftEffect <<< Cip30.getIcon
  getSupportedExtensions = H.liftEffect <<< Cip30.getSupportedExtensions
  isWalletAvailable = H.liftEffect <<< Cip30.isWalletAvailable

getNativeCoinBalance :: forall m. MonadCIP30 m => Api -> m Csl.BigNum
getNativeCoinBalance api = do
  walletBalanceCbor <- getBalance api
  let
    balance = fromMaybe Csl.value.zero $ Csl.value.fromHex walletBalanceCbor
  pure $ Csl.bigNum.divFloor (Csl.value.coin balance) (maybe Csl.bigNum.one identity (Csl.bigNum.fromStr "1000000"))

getNativeCoinBalanceString :: forall m. MonadCIP30 m => Api -> m String
getNativeCoinBalanceString api = do
  adaBalance <- getNativeCoinBalance api
  pure $ (Csl.bigNum.toStr adaBalance) <> " ₳"

getNativeAssetsBalance :: forall m. MonadCIP30 m => Api -> m (Maybe Csl.MultiAsset)
getNativeAssetsBalance api = do
  walletBalanceCbor <- getBalance api
  let
    balance = fromMaybe Csl.value.zero $ Csl.value.fromHex walletBalanceCbor
  pure $ Csl.value.multiasset balance

getTheAvailableWallets :: forall m. MonadCIP30 m => m (Array (Tuple WalletName String))
getTheAvailableWallets = do
  ws <- getAvailableWallets
  is <- sequence $ map getIcon ws
  pure $ zip ws is

getNetworkName :: forall m. MonadCIP30 m => Api -> m String
getNetworkName api = do
  id <- getNetworkId api
  pure
    $ case id of
        1 -> "Mainnet"
        0 -> "Preview"
        2 -> "Preprod"
        _ -> "Unknown"

getUserAddresses :: forall m. MonadCIP30 m => Api -> m (Array String)
getUserAddresses api = getUsedAddresses api Nothing

getUserFirstAddressBech32 :: forall m. MonadCIP30 m => Api -> m String
getUserFirstAddressBech32 api = do
  userAddresses <- getUserAddresses api
  pure
    $ case userAddresses !! 0 of
        Just firstAddrHex -> case Csl.address.fromHex firstAddrHex of
          Just firstAddr -> Csl.address.toBech32 firstAddr Nothing
          Nothing -> ""
        Nothing -> ""

enableWallet :: forall m. MonadCIP30 m => WalletName -> m Api
enableWallet wname = enable wname [ { cip: 30 } ]
