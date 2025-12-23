module Utils where

import Prelude
import Data.Formatter.Number (formatOrShowNumber)
import Data.Maybe (maybe)
import Data.Number as Number
import Data.String (drop, length, take)

shortString :: Int -> String -> String
shortString i s =
  let
    len = length s
  in
    if len > (2 * i) then
      take i s <> "..." <> drop (len - i) s
    else
      s

formatNumberFromStr ∷ String → String
formatNumberFromStr str = formatOrShowNumber "0,0" $ maybe 0.0 identity $ Number.fromString $ str
