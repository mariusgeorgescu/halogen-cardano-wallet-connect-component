module Components.WalletConnectComponent where

import Prelude
import Capabilities.MonadCIP30
import Cardano.Wallet.Cip30 (Api)
import Components.HTML.RenderUtils (renderDevider, renderLink)
import Csl as Csl
import Data.Array ((!!), null)
import Data.Maybe (Maybe(..), isJust)
import Data.Tuple (Tuple, fst, snd)
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.HTML.Properties.ARIA as HPA
import Type.Proxy (Proxy(..))
import Utils (formatNumberFromStr, shortString)

--------------------------------------------------------------------------------
-- Component Interface
--------------------------------------------------------------------------------
type Slot
  = H.Slot Query Output Unit

walletConnectProxy = Proxy :: Proxy "walletConnectComponent"

-- Customizable input: array of buttons to render
type ButtonConfig
  = { id :: String
    , label :: String
    , iconSrc :: String
    , classes :: Array String
    }

type Input
  = { buttons :: Array ButtonConfig }

-- No outputs for now
data Output
  = WalletConnectedEvent
  | WalletDisconnectedEvent
  | CustomButtonEvent String -- emits the button id

-- Public queries to update/query walletApi and state
data Query a
  = SetWalletApi (Maybe Api) a
  | GetWalletApi (Maybe Api -> a)
  | GetConnectedWalletInfo (Maybe ConnectedWalletInfo -> a)
  | GetAvailableWalletExtensions (Array (Tuple String String) -> a)

type ConnectedWalletInfo
  = { connectedWalletName :: String
    , connectedWalletIcon :: String
    , connectedWalletNetwork :: String
    , connectedWalletAddress :: String
    , connectedWalletNativeCoinBalance :: String
    }

type State
  = { availableWalletExtensions :: Array (Tuple String String)
    , connectedWalletInfo :: Maybe ConnectedWalletInfo
    , walletApi :: Maybe Api
    , customButtons :: Array ButtonConfig
    }

data Action
  = ConnectWallet String
  | DisconnectWallet
  | Receive Input
  | ClickCustomButton String

component ::
  forall m.
  MonadAff m =>
  MonadCIP30 m =>
  H.Component Query Input Output m
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
initialState :: Input -> State
initialState i =
  { availableWalletExtensions: []
  , connectedWalletInfo: Nothing
  , walletApi: Nothing
  , customButtons: i.buttons
  }

handleQuery ::
  forall m a.
  MonadAff m =>
  MonadCIP30 m =>
  Query a -> H.HalogenM State Action () Output m (Maybe a)
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

handleAction ::
  forall m.
  MonadAff m =>
  MonadCIP30 m =>
  Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  ConnectWallet wname -> do
    api <- enableWallet wname
    network <- getNetworkName api
    name <- getName wname
    icon <- getIcon wname
    adaBalance <- getNativeCoinBalanceString api
    userAddresses <- getUserAddresses api
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
    H.modify_ _ { walletApi = Just api, connectedWalletInfo = cw }
    H.raise WalletConnectedEvent
  DisconnectWallet -> do
    H.modify_ _ { walletApi = Nothing, connectedWalletInfo = Nothing }
    H.raise WalletDisconnectedEvent
  Receive i -> do
    H.modify_ _ { customButtons = i.buttons }
  ClickCustomButton bid -> do
    H.raise (CustomButtonEvent bid)

--------------------------------------------------------------------------------
-- Render (minimal placeholder)
--------------------------------------------------------------------------------
render :: forall m. State -> H.ComponentHTML Action () m
render s =
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
          [ HH.img [ HP.src "./images/walletsymbol.svg" ] ]
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
        [ HH.li_
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
                , HH.span_ [ HH.text (formatNumberFromStr wallet.connectedWalletNativeCoinBalance) ]
                ]
            ]
        , renderDevider "neutral"
        , HH.div_ (renderCustomDropdownButton <$> customButtons)
        , HH.li [ HE.onClick \_ -> DisconnectWallet ]
            [ HH.a_
                [ HH.div
                    [ HP.classes [ HH.ClassName "mask mask-hexagon  w-8" ] ]
                    [ HH.img [ HP.src "./images/disconnectsymbol.svg" ] ]
                , HH.text $ "Disconnect " <> wallet.connectedWalletName
                ]
            ]
        ]
    Nothing ->
      if null availableWalletExtensions then
        HH.div [ HP.classes [ HH.ClassName $ "dropdown-content z-40 card card-compact w-64 p-2  bg-" <> buttonColour <> "  text-" <> buttonColour <> "-content" ] ]
          [ HH.div [ HP.classes [ HH.ClassName "card-body" ] ]
              [ HH.h4 [ HP.classes [ HH.ClassName "card-title" ] ] [ HH.text "You do not have any wallet installed yet !" ]
              , HH.p_
                  [ HH.div
                      [ HP.classes [ HH.ClassName "mask mask-hexagon  w-8" ] ]
                      [ HH.img [ HP.src "./images/lace.png" ] ]
                  , renderLink "" "Try Lace" "http://www.lace.io"
                  ]
              ]
          ]
      else
        HH.ul
          [ HP.tabIndex 0
          , HP.classes [ HH.ClassName $ "dropdown-content menu  bg-" <> buttonColour <> "  text-" <> buttonColour <> "-content rounded-box z-40 w-64 p-2 " ]
          ]
          (renderWalletListItem <$> availableWalletExtensions)
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
