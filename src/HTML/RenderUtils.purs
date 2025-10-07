module Components.HTML.RenderUtils where

import Prelude
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

renderDevider :: forall w i. String -> HH.HTML w i
renderDevider deviderType = HH.div [ HP.classes [ HH.ClassName $ "divider divider-" <> deviderType ] ] []

renderLink :: forall w i. String -> String -> String -> HH.HTML w i
renderLink classes title link = HH.a [ HP.classes [ HH.ClassName $ "link " <> classes ], HP.target "_blank", HP.href link ] [ HH.text title ]