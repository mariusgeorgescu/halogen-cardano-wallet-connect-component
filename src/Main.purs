module Main where

import Prelude
import AppM (runAppM)
import Components.Home as Home
import AppEnv (defaultEnv)
import Effect (Effect)
import Halogen.Aff as HA
import Halogen.VDom.Driver (runUI)
import Store (initialStore)

main :: Effect Unit
main = do
  HA.runHalogenAff do
    rootComponent <- runAppM defaultEnv initialStore Home.component
    body <- HA.awaitBody
    runUI rootComponent {}
      body
