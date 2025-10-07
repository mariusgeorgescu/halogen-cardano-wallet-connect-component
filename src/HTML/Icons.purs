module Components.HTML.Icons
  ( activeSvgIcon
  , downSvgIcon
  , errorSvgIcon
  , finalSvgIcon
  , infoSvgIcon
  , successSvgIcon
  , upSvgIcon
  , warningSvgIcon
  )
  where

import Halogen.Svg.Attributes.Color (Color(..))
import Halogen.Svg.Attributes.StrokeLineCap (StrokeLineCap(..))
import Prelude
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.Svg.Attributes as SA
import Halogen.Svg.Attributes.StrokeLineJoin (StrokeLineJoin(..))
import Halogen.Svg.Elements as SE

altertSVG ∷ ∀ i p. String -> HH.HTML p i
altertSVG string =
  SE.svg
    [ SA.class_ $ HH.ClassName "h-6 w-6 shrink-0 stroke-current"
    , SA.fill NoColor
    , SA.viewBox 0.0 0.0 24.0 24.0
    ]
    [ SE.path
        [ SA.strokeLineCap LineCapRound
        , SA.strokeLineJoin LineJoinRound
        , SA.strokeWidth 2.0
        , HP.attr (HH.AttrName "d") string
        ]
    ]

infoSvgIcon ∷ ∀ i p. HH.HTML p i
infoSvgIcon = altertSVG "M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"

successSvgIcon ∷ ∀ i p. HH.HTML p i
successSvgIcon = altertSVG "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"

warningSvgIcon ∷ ∀ i p. HH.HTML p i
warningSvgIcon = altertSVG "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"

errorSvgIcon ∷ ∀ i p. HH.HTML p i
errorSvgIcon = altertSVG "M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"

upSvgIcon ∷ ∀ i p. HH.HTML p i
upSvgIcon = altertSVG "M5 15l7-7 7 7"

downSvgIcon ∷ ∀ i p. HH.HTML p i
downSvgIcon = altertSVG "M19 9l-7 7-7-7"

activeSvgIcon ∷ ∀ i p. HH.HTML p i
activeSvgIcon = altertSVG "M14 15V9L18 15V9 M9 9C10.6569 9 12 10.3431 12 12C12 13.6569 10.6569 15 9 15C7.34315 15 6 13.6569 6 12C6 10.3431 7.34315 9 9 9Z M1 15V9C1 5.68629 3.68629 3 7 3H17C20.3137 3 23 5.68629 23 9V15C23 18.3137 20.3137 21 17 21H7C3.68629 21 1 18.3137 1 15Z"

finalSvgIcon ∷ ∀ i p. HH.HTML p i
finalSvgIcon = altertSVG "M1 15V9C1 5.68629 3.68629 3 7 3H17C20.3137 3 23 5.68629 23 9V15C23 18.3137 20.3137 21 17 21H7C3.68629 21 1 18.3137 1 15Z M7 9C8.65685 9 10 10.3431 10 12C10 13.6569 8.65685 15 7 15C5.34315 15 4 13.6569 4 12C4 10.3431 5.34315 9 7 9Z M12 15V9L15 9 M17 15V9L20 9 M12.0001 12H14.5715 M17.0001 12H19.5715"


onSvgIcon ∷ ∀ i p. HH.HTML p i
onSvgIcon = altertSVG "M12 21l-12-18h24z"

offSvgIcon ∷ ∀ i p. HH.HTML p i
offSvgIcon = altertSVG "M12 21l-12-18h24z"