-- | Halogen component for Cardano wallet connection via CIP-30.
-- | Supports two render modes: Standalone (default) and Unified (combined
-- | profile selector + wallet info in a single avatar dropdown).
-- | Exposes Slot, Query, Output, Input, and component; parent uses _walletConnect proxy.
module Components.WalletConnectComponent where

import Prelude
import Cardano.Capabilities.Wallet.MonadCIP30
  ( class MonadCIP30
  , enableWallet
  , getName
  , getIcon
  , getNetworkName
  , getNativeCoinBalanceString
  , getUserFirstAddressBech32
  , getTheAvailableWallets
  )
import Cardano.Wallet.Cip30 (Api)
import Components.HTML.RenderUtils (renderDevider, renderLink)
import Data.Array (null)
import Data.Maybe (Maybe(..), fromMaybe, isJust, isNothing)
import Data.String.Common (replace) as Str
import Data.String.Pattern (Pattern(..), Replacement(..))
import Data.Tuple (Tuple, fst, snd)
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.HTML.Properties.ARIA as HPA
import Type.Proxy (Proxy(..))
import Utils (formatNumberFromStr, openUrl, shortString)
import Utxos.Sdk (UtxosConfig, UtxosWallet, utxosEnable, getCardanoApi, getUtxosUserAvatarUrl, getUtxosUserName, utxosOnramp)

--------------------------------------------------------------------------------
-- Component Interface
--------------------------------------------------------------------------------
-- | Slot type for the wallet connect component.
type Slot = H.Slot Query Output Unit

-- | Proxy for the wallet connect slot label (use with HH.slot).
_walletConnect :: Proxy "walletConnectComponent"
_walletConnect = Proxy

-- | Customizable input: array of buttons to render.
type ButtonConfig =
  { id :: String
  , label :: String
  , iconSrc :: String
  , classes :: Array String
  }

-- | Generic profile info for unified mode (no domain dependency).
type ProfileInfo =
  { id :: String
  , name :: String
  , subtitle :: String
  , thumbnailUri :: String
  }

-- | Render mode: Standalone (current default) or Unified (combined identity button).
data RenderMode
  = Standalone
  | Unified UnifiedConfig

-- | Configuration for unified render mode.
type UnifiedConfig =
  { profiles :: Array ProfileInfo
  , activeProfile :: Maybe ProfileInfo
  , actions :: Array ButtonConfig
  , pendingCount :: Int
  , createProfileLabel :: String
  }

-- | Input: custom buttons, asset URLs, render mode, and optional UTXOS config.
type Input =
  { buttons :: Array ButtonConfig
  , assets ::
      { connectIcon :: String
      , disconnectIcon :: String
      , onrampIcon :: String
      }
  , renderMode :: RenderMode
  , utxosConfig :: Maybe UtxosConfig
  , onrampUrl :: Maybe String
  -- | When false, Buy ADA still raises `FiatOnrampInitiatedEvent` but does not open the UTXOS SDK or extension URL (parent can toast, e.g. mainnet-only).
  , allowFiatOnramp :: Boolean
  }

-- | Output messages raised to the parent.
data Output
  = WalletConnectedEvent
  | WalletDisconnectedEvent
  | CustomButtonEvent String
  | ProfileSelectedEvent String
  | ActionItemEvent String
  | CreateProfileEvent
  | FiatOnrampInitiatedEvent

-- | Public queries to update/query walletApi and state.
data Query a
  = SetWalletApi (Maybe Api) a
  | GetWalletApi (Maybe Api -> a)
  | GetConnectedWalletInfo (Maybe ConnectedWalletInfo -> a)
  | GetAvailableWalletExtensions (Array (Tuple String String) -> a)
  | DisconnectWalletQuery a
  | RefreshWalletInfoQuery a

-- | Connected wallet display info.
type ConnectedWalletInfo =
  { connectedWalletName :: String
  , connectedWalletIcon :: String
  , connectedWalletNetwork :: String
  , connectedWalletAddress :: String
  , connectedWalletNativeCoinBalance :: String
  }

-- | How the current wallet was connected.
data WalletConnection
  = NotConnected
  | ViaExtension
  | ViaUtxos UtxosWallet

-- | Component state (internal).
type State =
  { availableWalletExtensions :: Array (Tuple String String)
  , connectedWalletInfo :: Maybe ConnectedWalletInfo
  , walletApi :: Maybe Api
  , customButtons :: Array ButtonConfig
  , assets :: { connectIcon :: String, disconnectIcon :: String, onrampIcon :: String }
  , renderMode :: RenderMode
  , utxosConfig :: Maybe UtxosConfig
  , onrampUrl :: Maybe String
  , allowFiatOnramp :: Boolean
  , walletConnection :: WalletConnection
  }

-- | Internal actions.
data Action
  = ConnectWallet String
  | ConnectUtxosWallet
  | OpenFiatOnramp
  | DisconnectWallet
  | Receive Input
  | ClickCustomButton String
  | SelectProfile String
  | ClickActionItem String
  | ClickCreateProfile

-- | Wallet connect Halogen component. Requires MonadAff and MonadCIP30.
component
  :: forall m
   . MonadAff m
  => MonadCIP30 m
  => H.Component Query Input Output m
component =
  H.mkComponent
    { initialState
    , render
    , eval:
        H.mkEval
          $ H.defaultEval
              { handleAction = handleAction
              , initialize = Nothing
              , handleQuery = handleQuery
              , receive = Just <<< Receive
              }
    }

--------------------------------------------------------------------------------
-- Evaluation
--------------------------------------------------------------------------------
-- | Build initial state from Input.
initialState :: Input -> State
initialState i =
  { availableWalletExtensions: []
  , connectedWalletInfo: Nothing
  , walletApi: Nothing
  , customButtons: i.buttons
  , assets: i.assets
  , renderMode: i.renderMode
  , utxosConfig: i.utxosConfig
  , onrampUrl: i.onrampUrl
  , allowFiatOnramp: i.allowFiatOnramp
  , walletConnection: NotConnected
  }

-- | Handle parent queries (SetWalletApi, GetWalletApi, etc.).
handleQuery
  :: forall m a
   . MonadAff m
  => MonadCIP30 m
  => Query a
  -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  SetWalletApi api next -> do
    ws <- getTheAvailableWallets
    H.modify_ _ { walletApi = api, availableWalletExtensions = ws }
    pure (Just next)
  GetWalletApi k -> do
    api <- H.gets _.walletApi
    pure $ Just (k api)
  GetConnectedWalletInfo k -> do
    wi <- H.gets _.connectedWalletInfo
    pure $ Just (k wi)
  GetAvailableWalletExtensions k -> do
    ws <- H.gets _.availableWalletExtensions
    pure $ Just (k ws)
  DisconnectWalletQuery next -> do
    handleAction DisconnectWallet
    pure (Just next)
  RefreshWalletInfoQuery next -> do
    st <- H.get
    case st.walletApi, st.connectedWalletInfo of
      Just api, Just cw -> do
        network <- getNetworkName api
        adaBalance <- getNativeCoinBalanceString api
        firstAddrBech32 <- getUserFirstAddressBech32 api
        H.modify_ _
          { connectedWalletInfo = Just cw
              { connectedWalletNetwork = network
              , connectedWalletAddress = firstAddrBech32
              , connectedWalletNativeCoinBalance = adaBalance
              }
          }
        pure (Just next)
      _, _ -> pure (Just next)

-- | Handle internal actions.
handleAction
  :: forall m
   . MonadAff m
  => MonadCIP30 m
  => Action
  -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  ConnectWallet wname -> do
    api <- enableWallet wname
    network <- getNetworkName api
    name <- getName wname
    icon <- getIcon wname
    adaBalance <- getNativeCoinBalanceString api
    firstAddrBech32 <- getUserFirstAddressBech32 api
    let
      cw =
        Just
          { connectedWalletName: name
          , connectedWalletNetwork: network
          , connectedWalletAddress: firstAddrBech32
          , connectedWalletNativeCoinBalance: adaBalance
          , connectedWalletIcon: icon
          }
    H.modify_ _ { walletApi = Just api, connectedWalletInfo = cw, walletConnection = ViaExtension }
    H.raise WalletConnectedEvent
  ConnectUtxosWallet -> do
    st <- H.get
    case st.utxosConfig of
      Nothing -> pure unit
      Just cfg -> do
        utxosWallet <- liftAff $ utxosEnable cfg
        let api = getCardanoApi utxosWallet
        network <- getNetworkName api
        adaBalance <- getNativeCoinBalanceString api
        firstAddrBech32 <- getUserFirstAddressBech32 api
        let
          avatarUrl = fromMaybe cfg.walletIcon (getUtxosUserAvatarUrl utxosWallet)
          userName = fromMaybe cfg.walletLabel (getUtxosUserName utxosWallet)
          cw =
            Just
              { connectedWalletName: userName
              , connectedWalletIcon: avatarUrl
              , connectedWalletNetwork: network
              , connectedWalletAddress: firstAddrBech32
              , connectedWalletNativeCoinBalance: adaBalance
              }
        H.modify_ _
          { walletApi = Just api
          , connectedWalletInfo = cw
          , walletConnection = ViaUtxos utxosWallet
          }
        H.raise WalletConnectedEvent
  OpenFiatOnramp -> do
    st <- H.get
    case st.walletConnection, st.connectedWalletInfo of
      ViaUtxos utxosWallet, _ -> do
        if st.allowFiatOnramp then liftAff $ utxosOnramp utxosWallet
        else pure unit
        H.raise FiatOnrampInitiatedEvent
      ViaExtension, Just cw
        | Just url <- st.onrampUrl -> do
            if st.allowFiatOnramp then do
              let fullUrl = Str.replace (Pattern "{address}") (Replacement cw.connectedWalletAddress) url
              liftEffect $ openUrl fullUrl
            else pure unit
            H.raise FiatOnrampInitiatedEvent
      _, _ -> pure unit
  DisconnectWallet -> do
    H.modify_ _ { walletApi = Nothing, connectedWalletInfo = Nothing, walletConnection = NotConnected }
    H.raise WalletDisconnectedEvent
  Receive i -> do
    H.modify_ _ { customButtons = i.buttons, assets = i.assets, renderMode = i.renderMode, utxosConfig = i.utxosConfig, onrampUrl = i.onrampUrl, allowFiatOnramp = i.allowFiatOnramp }
  ClickCustomButton bid -> do
    H.raise (CustomButtonEvent bid)
  SelectProfile pid -> do
    H.raise (ProfileSelectedEvent pid)
  ClickActionItem aid -> do
    H.raise (ActionItemEvent aid)
  ClickCreateProfile -> do
    H.raise CreateProfileEvent

--------------------------------------------------------------------------------
-- Render
--------------------------------------------------------------------------------
-- | Route to standalone or unified render based on mode.
render :: forall m. State -> H.ComponentHTML Action () m
render s = case s.renderMode of
  Standalone -> renderStandalone s
  Unified cfg -> case s.connectedWalletInfo of
    Nothing -> renderStandalone s
    Just wallet -> renderUnified s cfg wallet

--------------------------------------------------------------------------------
-- Standalone Render (original behavior)
--------------------------------------------------------------------------------
renderStandalone :: forall m. State -> H.ComponentHTML Action () m
renderStandalone s =
  HH.div [ HP.classes [ HH.ClassName "flex justify-end", HH.ClassName "dropdown dropdown-hover dropdown-bottom dropdown-end" ] ]
    [ HH.div
        [ HP.tabIndex 0
        , HPA.role "button"
        , HP.classes [ HH.ClassName $ "btn btn-" <> buttonColour <> "  text-" <> buttonColour <> "-content min-w-40" ]
        ]
        (printConnectedWallet)
    , renderWalletWidgetDetails s
    ]
  where
  buttonColour = if isJust (s.connectedWalletInfo) then "primary" else "secondary"

  printConnectedWallet = case s.connectedWalletInfo of
    Nothing ->
      [ HH.text "Connect"
      , HH.div
          [ HP.classes [ HH.ClassName "mask mask-hexagon  w-8" ] ]
          [ HH.img [ HP.src s.assets.connectIcon ] ]
      ]
    Just wallet ->
      [ HH.text "Connected"
      , HH.div
          [ HP.classes [ HH.ClassName "mask mask-hexagon bg-base-100 w-8" ] ]
          [ HH.img [ HP.src wallet.connectedWalletIcon ] ]
      ]

  renderWalletWidgetDetails { availableWalletExtensions, connectedWalletInfo, customButtons } = case connectedWalletInfo of
    Just wallet ->
      HH.ul
        [ HP.tabIndex 0
        , HP.classes [ HH.ClassName $ "menu dropdown-content bg-" <> buttonColour <> "  text-" <> buttonColour <> "-content rounded-box z-40 min-w-64 w-fit p-2 " ]
        ]
        ( [ HH.li_
              [ HH.div
                  [ HP.classes [ HH.ClassName "flex items-center gap-2" ] ]
                  [ HH.span [ HP.classes [ HH.ClassName "font-bold" ] ] [ HH.text "Network:" ]
                  , HH.span_ [ HH.text wallet.connectedWalletNetwork ]
                  ]
              , HH.div
                  [ HP.classes [ HH.ClassName "flex items-center gap-2" ] ]
                  [ HH.span [ HP.classes [ HH.ClassName "font-bold" ] ] [ HH.text "Address:" ]
                  , HH.span_ [ HH.text (shortString 10 wallet.connectedWalletAddress) ]
                  ]
              , HH.div
                  [ HP.classes [ HH.ClassName "flex items-center gap-2" ] ]
                  [ HH.span [ HP.classes [ HH.ClassName "font-bold" ] ] [ HH.text "Balance:" ]
                  , HH.span_ [ HH.text $ (formatNumberFromStr wallet.connectedWalletNativeCoinBalance) <> " ₳" ]
                  ]
              ]
          ]
            <> renderOnrampItem s
            <>
              [ renderDevider "neutral"
              , HH.div_ (renderCustomDropdownButton <$> customButtons)
              , HH.li [ HE.onClick \_ -> DisconnectWallet ]
                  [ HH.a_
                      [ HH.div
                          [ HP.classes [ HH.ClassName "mask mask-hexagon  w-8" ] ]
                          [ HH.img [ HP.src s.assets.disconnectIcon ] ]
                      , HH.text $ "Disconnect " <> wallet.connectedWalletName
                      ]
                  ]
              ]
        )
    Nothing ->
      if null availableWalletExtensions && isNothing s.utxosConfig then
        HH.div [ HP.classes [ HH.ClassName $ "dropdown-content z-40 card card-compact w-64 p-2  bg-" <> buttonColour <> "  text-" <> buttonColour <> "-content" ] ]
          [ HH.div [ HP.classes [ HH.ClassName "card-body" ] ]
              [ HH.h4 [ HP.classes [ HH.ClassName "card-title" ] ] [ HH.text "You do not have any wallet installed yet !" ]
              , HH.p_
                  [ HH.div
                      [ HP.classes [ HH.ClassName "mask mask-hexagon  w-8" ] ]
                      [ HH.img [ HP.src s.assets.connectIcon ] ]
                  , renderLink "" "Try Lace" "http://www.lace.io"
                  ]
              ]
          ]
      else
        HH.ul
          [ HP.tabIndex 0
          , HP.classes [ HH.ClassName $ "dropdown-content menu  bg-" <> buttonColour <> "  text-" <> buttonColour <> "-content rounded-box z-40 w-64 p-2 " ]
          ]
          ( (renderWalletListItem <$> availableWalletExtensions)
              <> case s.utxosConfig of
                Nothing -> []
                Just cfg ->
                  (if null availableWalletExtensions then [] else [ renderDevider "neutral" ])
                    <>
                      [ HH.li [ HE.onClick \_ -> ConnectUtxosWallet ]
                          [ HH.a_
                              [ HH.div
                                  [ HP.classes [ HH.ClassName "mask mask-hexagon bg-base-100 w-8" ] ]
                                  [ HH.img [ HP.src cfg.walletIcon ] ]
                              , HH.text cfg.walletLabel
                              ]
                          ]
                      ]
          )
    where
    renderWalletListItem wnameTuple =
      let
        wname = fst wnameTuple

        wicon = snd wnameTuple
      in
        HH.li [ HE.onClick \_ -> ConnectWallet wname ]
          [ HH.a_
              [ HH.div
                  [ HP.classes [ HH.ClassName "mask mask-hexagon bg-base-100 w-8" ] ]
                  [ HH.img [ HP.src wicon ]
                  ]
              , HH.text wname
              ]
          ]

    renderCustomDropdownButton b =
      HH.li [ HE.onClick \_ -> ClickCustomButton b.id ]
        [ HH.a_
            [ HH.div
                [ HP.classes [ HH.ClassName "mask mask-hexagon  w-8" ] ]
                [ HH.img [ HP.src b.iconSrc ] ]
            , HH.text b.label
            ]
        ]

-- | Render on-ramp item if available (ViaUtxos or ViaExtension with onrampUrl).
renderOnrampItem :: forall m. State -> Array (H.ComponentHTML Action () m)
renderOnrampItem s = case s.walletConnection of
  ViaUtxos _ ->
    [ HH.li [ HE.onClick \_ -> OpenFiatOnramp ]
        [ HH.a_
            [ HH.div
                [ HP.classes [ HH.ClassName "mask mask-hexagon w-8" ] ]
                [ HH.img [ HP.src s.assets.onrampIcon ] ]
            , HH.text "Buy ADA"
            ]
        ]
    ]
  ViaExtension
    | isJust s.onrampUrl ->
        [ HH.li [ HE.onClick \_ -> OpenFiatOnramp ]
            [ HH.a_
                [ HH.div
                    [ HP.classes [ HH.ClassName "mask mask-hexagon w-8" ] ]
                    [ HH.img [ HP.src s.assets.onrampIcon ] ]
                , HH.text "Buy ADA"
                ]
            ]
        ]
  _ -> []

--------------------------------------------------------------------------------
-- Unified Render (combined profile selector + wallet info)
--------------------------------------------------------------------------------
renderUnified :: forall m. State -> UnifiedConfig -> ConnectedWalletInfo -> H.ComponentHTML Action () m
renderUnified s cfg wallet =
  HH.div [ HP.classes [ HH.ClassName "flex justify-end dropdown dropdown-bottom dropdown-end" ] ]
    [ renderUnifiedTrigger cfg wallet
    , renderUnifiedDropdown s cfg wallet
    ]

renderUnifiedTrigger :: forall m. UnifiedConfig -> ConnectedWalletInfo -> H.ComponentHTML Action () m
renderUnifiedTrigger cfg wallet =
  HH.div
    [ HP.tabIndex 0
    , HPA.role "button"
    , HP.classes [ HH.ClassName "btn btn-ghost btn-circle avatar" ]
    ]
    [ case cfg.activeProfile of
        Just p ->
          HH.div [ HP.classes [ HH.ClassName "w-10 rounded-full" ] ]
            [ HH.img [ HP.src p.thumbnailUri, HP.alt p.name ] ]
        Nothing ->
          HH.div [ HP.classes [ HH.ClassName "w-10 rounded-full" ] ]
            [ HH.img [ HP.src wallet.connectedWalletIcon, HP.alt wallet.connectedWalletName ] ]
    ]

renderUnifiedDropdown :: forall m. State -> UnifiedConfig -> ConnectedWalletInfo -> H.ComponentHTML Action () m
renderUnifiedDropdown s cfg wallet =
  HH.ul
    [ HP.tabIndex 0
    , HP.classes [ HH.ClassName "dropdown-content menu menu-sm bg-base-100 text-base-content rounded-box z-50 mt-3 w-64 p-2 shadow-lg" ]
    ]
    ( -- Section 1: Profiles
      (map (renderUnifiedProfileItem cfg.activeProfile) cfg.profiles)
        <>
          [ HH.li [ HE.onClick \_ -> ClickCreateProfile ]
              [ HH.a [ HP.classes [ HH.ClassName "text-primary font-semibold" ] ]
                  [ HH.text cfg.createProfileLabel ]
              ]
          ]
        -- Divider
        <> [ renderDevider "neutral" ]
        -- Section 2: Actions
        <> (map (renderUnifiedActionItem cfg.pendingCount) cfg.actions)
        -- Divider
        <> [ renderDevider "neutral" ]
        -- Section 3: Wallet info + on-ramp + disconnect
        <>
          [ HH.li_
              [ HH.div [ HP.classes [ HH.ClassName "flex items-center gap-2 px-2 py-1" ] ]
                  [ HH.div
                      [ HP.classes [ HH.ClassName "mask mask-hexagon bg-base-100 w-6" ] ]
                      [ HH.img [ HP.src wallet.connectedWalletIcon ] ]
                  , HH.span [ HP.classes [ HH.ClassName "font-medium text-sm" ] ] [ HH.text "Connected" ]
                  ]
              , HH.div [ HP.classes [ HH.ClassName "flex flex-col gap-1 px-2 py-1 text-xs opacity-70" ] ]
                  [ HH.div_ [ HH.text $ wallet.connectedWalletNetwork <> " \x00B7 " <> (formatNumberFromStr wallet.connectedWalletNativeCoinBalance) <> " \x20B3" ]
                  , HH.div_ [ HH.text $ shortString 10 wallet.connectedWalletAddress ]
                  ]
              ]
          ]
        <> renderOnrampItem s
        <>
          [ HH.li [ HE.onClick \_ -> DisconnectWallet ]
              [ HH.a_
                  [ HH.div
                      [ HP.classes [ HH.ClassName "mask mask-hexagon w-8" ] ]
                      [ HH.img [ HP.src s.assets.disconnectIcon ] ]
                  , HH.text $ "Disconnect " <> wallet.connectedWalletName
                  ]
              ]
          ]
    )

renderUnifiedProfileItem :: forall m. Maybe ProfileInfo -> ProfileInfo -> H.ComponentHTML Action () m
renderUnifiedProfileItem activeProfile p =
  let
    isActive = case activeProfile of
      Just a -> a.id == p.id
      Nothing -> false
  in
    HH.li [ HE.onClick \_ -> SelectProfile p.id ]
      [ HH.a_
          [ HH.div [ HP.classes [ HH.ClassName "flex items-center gap-3 w-full" ] ]
              [ HH.div [ HP.classes [ HH.ClassName "avatar" ] ]
                  [ HH.div [ HP.classes [ HH.ClassName "w-8 rounded-full" ] ]
                      [ HH.img [ HP.src p.thumbnailUri, HP.alt p.name ] ]
                  ]
              , HH.div [ HP.classes [ HH.ClassName "flex-1 min-w-0" ] ]
                  [ HH.div [ HP.classes [ HH.ClassName "font-medium truncate" ] ] [ HH.text p.name ]
                  , HH.div [ HP.classes [ HH.ClassName "text-xs opacity-60" ] ] [ HH.text p.subtitle ]
                  ]
              , if isActive then HH.span [ HP.classes [ HH.ClassName "text-success text-sm" ] ] [ HH.text "\x2713" ]
                else HH.text ""
              ]
          ]
      ]

renderUnifiedActionItem :: forall m. Int -> ButtonConfig -> H.ComponentHTML Action () m
renderUnifiedActionItem pendingCount item =
  HH.li [ HE.onClick \_ -> ClickActionItem item.id ]
    [ HH.a [ HP.classes [ HH.ClassName "flex items-center justify-between" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "flex items-center gap-2" ] ]
            [ HH.div
                [ HP.classes [ HH.ClassName "mask mask-hexagon w-8" ] ]
                [ HH.img [ HP.src item.iconSrc ] ]
            , HH.text item.label
            ]
        , if item.id == "my-dojo" && pendingCount > 0 then
            HH.span [ HP.classes [ HH.ClassName "badge badge-sm badge-error" ] ]
              [ HH.text (show pendingCount) ]
          else HH.text ""
        ]
    ]
