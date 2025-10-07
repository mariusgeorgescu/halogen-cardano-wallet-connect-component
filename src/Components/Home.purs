module Components.Home where

import Prelude
import AppEnv (Env)
import Capabilities.MonadCIP30 (class MonadCIP30)
import Components.HTML.RenderUtils (renderProfessionalServicesSection, renderCexplorerPoolGraphSection, renderHeroSection, renderPoolOverviewSection, renderFooterSection) as RU
import Components.NavBar as NavBar
import Control.Monad.Reader.Class (class MonadAsk, asks)
import Data.Array (cons, filter)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.Store.Monad (class MonadStore)
import Store as Store

--------------------------------------------------------------------------------
-- * Utils
--------------------------------------------------------------------------------
type Toast
  = { remainingSeconds :: Int
    , alertType :: String
    , message :: String
    }

getToast :: Toast -> Tuple String String
getToast t = Tuple t.alertType t.message

decrementToats :: Array Toast -> Array Toast
decrementToats ts = (\t -> t { remainingSeconds = t.remainingSeconds - 1 }) <$> ts

clearToasts :: Array Toast -> Array Toast
clearToasts ts = filter ((_ > 0) <<< _.remainingSeconds) ts

--------------------------------------------------------------------------------
-- * Component Definition
--------------------------------------------------------------------------------
type Slots
  = ( navbarWidget :: NavBar.Slot
    )

data Page
  = MainPage

derive instance eqValue :: Eq Page

type Input
  = {
    }

type State
  = { toasts :: Array Toast
    , currentPage :: Page
    }

data Action
  = Initialize
  | HandleNavBarOutput NavBar.Output

component ::
  forall query output m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadStore Store.Action Store.Store m =>
  MonadAsk Env m =>
  H.Component query Input output m
component =
  H.mkComponent
    { initialState
    , render
    , eval:
        H.mkEval
          $ H.defaultEval
              { handleAction = handleAction
              , initialize = Just Initialize
              }
    }

--------------------------------------------------------------------------------
-- * Component Evaluation Logic
--------------------------------------------------------------------------------
initialState :: Input -> State
initialState i = { currentPage: MainPage, toasts: [] }

handleAction ::
  forall output m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadStore Store.Action Store.Store m =>
  MonadAsk Env m =>
  Action -> H.HalogenM State Action Slots output m Unit
handleAction action = case action of
  Initialize -> pure unit
  HandleNavBarOutput navbarout -> case navbarout of
    NavBar.HomeEvent -> do
      pure unit
    NavBar.WalletConnectEvent -> pure unit
    NavBar.InvalidNetworkEvent -> do
      cardanoNetwork <- asks _.blockchainProviderConfig.cardanoNetwork
      let
        newToast = { remainingSeconds: 5, alertType: "error", message: "Your wallet has to be connected to Cardano " <> cardanoNetwork <> " network" }
      H.modify_ \s -> s { toasts = newToast `cons` s.toasts }

--------------------------------------------------------------------------------
-- * Component Rendering
--------------------------------------------------------------------------------
render ::
  forall m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadStore Store.Action Store.Store m =>
  MonadAsk Env m =>
  State -> H.ComponentHTML Action Slots m
render s =
  HH.div_
    [ renderWalletWidgetSlot
    , RU.renderHeroSection
    , RU.renderProfessionalServicesSection
    , RU.renderPoolOverviewSection
    , RU.renderCexplorerPoolGraphSection
    , RU.renderFooterSection
    ]

renderWalletWidgetSlot ::
  forall m.
  MonadAff m =>
  MonadAsk Env m =>
  MonadCIP30 m =>
  MonadStore Store.Action Store.Store m =>
  H.ComponentHTML Action Slots m
renderWalletWidgetSlot = HH.slot NavBar.navbarProxy unit NavBar.component unit HandleNavBarOutput
