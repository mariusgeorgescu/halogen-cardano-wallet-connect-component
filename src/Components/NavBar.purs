module Components.NavBar where

import Prelude
import AppEnv (Env)
import Capabilities.MonadCIP30 (class MonadCIP30)
import Cardano.Wallet.Cip30 (Api)
import Components.WalletConnectComponent as WCC
import Control.Monad.Reader.Class (class MonadAsk)
import Data.Maybe (Maybe(..))
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP  
import Halogen.Store.Connect (Connected, connect)
import Halogen.Store.Monad (class MonadStore, updateStore)
import Halogen.Store.Select (selectAll)
import Store as Store
import Type.Proxy (Proxy(..))

--------------------------------------------------------------------------------
-- * Component Interface
--------------------------------------------------------------------------------
type Slot
  = forall query. H.Slot query Output Unit

navbarProxy = Proxy :: Proxy "navbarWidget"

type Input
  = Unit

type StoreContext
  = Store.Store

data Output
  = WalletConnectEvent
  | InvalidNetworkEvent
  | HomeEvent

--------------------------------------------------------------------------------
-- * Child Slots
--------------------------------------------------------------------------------
type Slots
  = ( walletConnectComponent :: H.Slot WCC.Query WCC.Output Unit
    )

--------------------------------------------------------------------------------
-- * Component Definition
--------------------------------------------------------------------------------
type State
  = { walletApi :: Maybe Api
    }

data Action
  = Initialize
  | Receive (Connected StoreContext Input)
  | HandleWalletConnectOutput WCC.Output
  | HomeButton

component ::
  forall query m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadAsk Env m =>
  MonadStore Store.Action Store.Store m =>
  H.Component query Input Output m
component =
  connect (selectAll)
    $ H.mkComponent
        { initialState
        , render
        , eval:
            H.mkEval
              H.defaultEval
                { handleAction = handleAction
                , initialize = Just Initialize
                , receive = Just <<< Receive
                }
        }

--------------------------------------------------------------------------------
-- * Component Evalution Logic
--------------------------------------------------------------------------------
initialState :: Connected StoreContext Input -> State
initialState x =
  { walletApi: x.context.walletApi
  }

handleAction ::
  forall m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadAsk Env m =>
  MonadStore Store.Action Store.Store m =>
  Action → H.HalogenM State Action Slots Output m Unit
handleAction = case _ of
  Initialize -> do
    walletApi <- H.gets _.walletApi
    void $ H.query WCC.walletConnectProxy unit (WCC.SetWalletApi walletApi unit)
  Receive x -> do
    H.modify_ _ { walletApi = x.context.walletApi }
    handleAction Initialize
  HandleWalletConnectOutput out -> case out of
    WCC.WalletConnectedEvent -> H.raise WalletConnectEvent
    WCC.WalletDisconnectedEvent -> do
      updateStore Store.Disconnect
      H.raise WalletConnectEvent
    WCC.CustomButtonEvent bid -> case bid of
      "home" -> H.raise HomeEvent
      "delegate" -> pure unit
      _ -> pure unit
  HomeButton -> H.raise HomeEvent

--------------------------------------------------------------------------------
-- * Component Rendering
--------------------------------------------------------------------------------
render :: forall m. MonadAff m => MonadCIP30 m => State -> H.ComponentHTML Action Slots m
render state =
  HH.div
    [ HP.classes [ HH.ClassName "bg-base-100 text-base-content sticky top-0 z-30 flex h-16 w-full justify-center bg-opacity-90 backdrop-blur transition-shadow duration-100 [transform:translate3d(0,0,0)] shadow-sm" ]
    ]
    [ HH.div
        [ HP.classes [ HH.ClassName "navbar bg-neutral text-neutral-content gap-4" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "flex-1" ] ]
            [ HH.button
                ([ HP.classes [ HH.ClassName ("btn btn-ghost") ], HE.onClick (\_ -> HomeButton) ])
                [ HH.div [ HP.classes [ HH.ClassName "text-lg" ] ]
                    [ HH.text "E7D" ]
                , HH.div [ HP.classes [ HH.ClassName "text-xs" ] ]
                    [ HH.text " </alpha>" ]
                ]
            ]
        , HH.div [ HP.classes [ HH.ClassName "flex-2 flex justify-end" ] ]
            [ HH.slot WCC.walletConnectProxy unit WCC.component { buttons: customButtons } HandleWalletConnectOutput
            ]
        , HH.div [ HP.classes [ HH.ClassName "flex-none" ] ] []
        ]
    ]
  where
  customButtons =
    [ { id: "home", label: "Home", iconSrc: "./images/home-symbol.svg", classes: [ "btn-secondary" ] }
    , { id: "delegate", label: "Delegate", iconSrc: "./images/createsymbol.svg", classes: [ "btn-primary" ] }
    ]
