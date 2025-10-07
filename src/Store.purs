module Store where

import Prelude
import Cardano.Wallet.Cip30 (Api)
import Data.Array (cons, filter)
import Data.Maybe (Maybe(..))

type Store
  = { walletApi :: Maybe Api
    , waitingforConfirmation :: Array String
    }

initialStore :: Store
initialStore = { walletApi: Nothing, waitingforConfirmation: [] }

data Action
  = Connect Api
  | Disconnect
  | AddToWaitingList String
  | RemoveFromWaitingList String

reduce :: Store -> Action -> Store
reduce store = case _ of
  Connect api -> store { walletApi = Just api }
  Disconnect -> store { walletApi = Nothing }
  AddToWaitingList raffleizeId -> store { waitingforConfirmation = raffleizeId `cons` store.waitingforConfirmation }
  RemoveFromWaitingList raffleizeId -> store { waitingforConfirmation = filter (not <<< (==) raffleizeId) store.waitingforConfirmation }
