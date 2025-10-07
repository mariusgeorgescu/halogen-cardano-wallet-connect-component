module Utils where

import Prelude
import Data.Array as A
import Data.DateTime (adjust)
import Data.DateTime.Instant (instant, toDateTime)
import Data.Either (hush)
import Data.Formatter.DateTime (formatDateTime)
import Data.Formatter.Number (formatOrShowNumber)
import Data.Maybe (Maybe, fromMaybe, maybe)
import Data.Number as Number
import Data.String (drop, length, take)
import Data.String as String
import Data.Time.Duration (Milliseconds(..), Minutes, negateDuration)
import Data.Tuple (Tuple)

enumerate :: ∀ a. Array a -> Array (Tuple Int a)
enumerate arr = A.zip (A.range 0 $ A.length arr) arr

printPOSIX ∷ String -> Minutes → Number → Maybe String
printPOSIX format tzoffset n = do
  dt <- toDateTime <$> instant (Milliseconds n)
  localdt <- adjust (negateDuration (tzoffset)) dt
  fdt <- hush $ formatDateTime format localdt
  pure fdt

printPOSIX' ∷ Minutes → Number → String
printPOSIX' tzoffset = fromMaybe "" <<< printPOSIX "D-MMM-YYYY HH:mm" tzoffset

printPOSIX'' ∷ Minutes → Number → String
printPOSIX'' tzoffset = fromMaybe "" <<< printPOSIX "YYYY-MM-DDTHH:mm" tzoffset

shortString :: Int -> String -> String
shortString i s =
  let
    len = length s
  in
    if len > (2 * i) then
      take i s <> "..." <> drop (len - i) s
    else
      s

trimQuotes :: String -> String
trimQuotes s = String.drop 1 $ String.take (String.length s - 1) s

formatNumberFromStr ∷ String → String
formatNumberFromStr str = formatOrShowNumber "0,0" $ maybe 0.0 identity $ Number.fromString $ str
