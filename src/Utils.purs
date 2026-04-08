-- | Utility functions used by the wallet connect component.
module Utils where

import Prelude
import Data.Formatter.Number (formatOrShowNumber)
import Data.Maybe (maybe)
import Data.Number as Number
import Data.String (drop, length, take)
import Effect (Effect)

foreign import _openUrl :: String -> Effect Unit

-- | Open a URL in a new browser tab.
openUrl :: String -> Effect Unit
openUrl = _openUrl

-- | Truncate string to first and last n chars with "..." in the middle.
shortString :: Int -> String -> String
shortString i s =
  let
    len = length s
  in
    if len > (2 * i) then
      take i s <> "..." <> drop (len - i) s
    else
      s

-- | Format a numeric string for display (e.g. balance).
formatNumberFromStr :: String -> String
formatNumberFromStr str = formatOrShowNumber "0,0" $ maybe 0.0 identity $ Number.fromString $ str
