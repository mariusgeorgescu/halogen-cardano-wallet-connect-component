module Components.HTML.RenderUtils where

import Prelude
import Components.HTML.Icons (activeSvgIcon, downSvgIcon, errorSvgIcon, finalSvgIcon, infoSvgIcon, successSvgIcon, upSvgIcon, warningSvgIcon)
import DOM.HTML.Indexed (HTMLinput, HTMLtextarea)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.String (take, length)
import Data.Tuple (Tuple(..))
import Formless as F
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

-- ==============================================================================
-- INPUT DATA
-- ==============================================================================
type Labelled input output
  = { label :: String
    , state :: F.FieldState input String output
    }

-- Attach a label and error text to a form input
withLabel ::
  forall input output action slots m.
  Labelled input output ->
  H.ComponentHTML action slots m ->
  H.ComponentHTML action slots m
withLabel { label, state } html =
  let
    (Tuple errorMsg inputColor) = case state.result of
      Just (Left e) -> Tuple e "input-secondary"
      _ -> Tuple "" "input-error"
  in
    HH.div [ HP.classes [ HH.ClassName $ "grid grid-cols-1 gap-1" ] ]
      [ HH.label [ HP.classes [ HH.ClassName $ "label " <> inputColor ] ]
          [ HH.span [ HP.classes [ HH.ClassName "primary-content" ] ] [ HH.text label ] ]
      , html
      , HH.small [ HP.classes [ HH.ClassName "bg-error text-error-content" ] ] [ HH.text errorMsg ]
      ]

type TextInput action output
  = { label :: String
    , state :: F.FieldState String String output
    , action :: F.FieldAction action String String output
    }

textInput ::
  forall output action slots m.
  TextInput action output ->
  Array (HP.IProp HTMLinput action) ->
  H.ComponentHTML action slots m
textInput { label, state, action } =
  withLabel { label, state } <<< HH.input
    <<< append
        [ HP.value state.value
        , case state.result of
            Nothing -> HP.attr (HH.AttrName "aria-touched") "false"
            Just (Left _) -> HP.attr (HH.AttrName "aria-invalid") "true"
            Just (Right _) -> HP.attr (HH.AttrName "aria-invalid") "false"
        , HE.onValueInput action.handleChange
        , HE.onBlur action.handleBlur
        , HP.classes [ HH.ClassName "input input-bordered input-secondary w-full max-w-xs" ]
        ]

textInput_ ::
  forall output action slots m.
  TextInput action output ->
  H.ComponentHTML action slots m
textInput_ = flip textInput []

type Textarea action output
  = { label :: String
    , state :: F.FieldState String String output
    , action :: F.FieldAction action String String output
    }

textarea ::
  forall output action slots m.
  Textarea action output ->
  Array (HP.IProp HTMLtextarea action) ->
  H.ComponentHTML action slots m
textarea { label, state, action } =
  withLabel { label, state } <<< HH.textarea
    <<< append
        [ HP.value state.value
        , HE.onValueInput action.handleChange
        , HE.onBlur action.handleBlur
        , HP.classes [ HH.ClassName "textarea textarea-secondary textarea-bordered  w-full max-w-xs" ]
        ]

textarea_ ::
  forall output action slots m.
  Textarea action output ->
  H.ComponentHTML action slots m
textarea_ = flip textarea []

type Checkbox error action
  = { label :: String
    , state :: F.FieldState Boolean error Boolean
    , action :: F.FieldAction action Boolean error Boolean
    }

checkboxConsent ::
  forall error action slots m.
  Checkbox error action ->
  Array (HP.IProp HTMLinput action) ->
  H.ComponentHTML action slots m
checkboxConsent { label, state, action } props =
  HH.fieldset_
    [ HH.label_
        [ HH.input
            $ flip append props
                [ HP.type_ HP.InputCheckbox
                , HP.checked state.value
                , HE.onChecked action.handleChange
                , HE.onBlur action.handleBlur
                ]
        , HH.text label
        ]
    ]

checkbox ::
  forall error action slots m.
  Checkbox error action ->
  Array (HP.IProp HTMLinput action) ->
  H.ComponentHTML action slots m
checkbox { label, state, action } props =
  HH.fieldset_
    [ HH.label_
        [ HH.text label
        , HH.input
            $ flip append props
                [ HP.type_ HP.InputCheckbox
                , HP.checked state.value
                , HE.onChecked action.handleChange
                , HE.onBlur action.handleBlur
                ]
        ]
    ]

checkbox_ ::
  forall error action slots m.
  Checkbox error action ->
  H.ComponentHTML action slots m
checkbox_ = flip checkbox []

-- <label class="swap">
--   <input type="checkbox" />
--   <div class="swap-on">ON</div>
--   <div class="swap-off">OFF</div>
-- </label>
swap ::
  forall error action slots m.
  H.ComponentHTML action slots m ->
  H.ComponentHTML action slots m ->
  Checkbox error action ->
  Array (HP.IProp HTMLinput action) ->
  H.ComponentHTML action slots m
swap onHTML offHTML { label, state, action } props =
  HH.fieldset [ HP.classes [ HH.ClassName "grid grid-cols-1 gap-1" ] ]
    [ HH.text label
    , HH.label [ HP.classes [ HH.ClassName "swap swap-rotate" ] ]
        [ HH.input
            $ flip append props
                [ HP.type_ HP.InputCheckbox
                , HP.checked state.value
                , HE.onChecked action.handleChange
                , HE.onBlur action.handleBlur
                ]
        , HH.div [ HP.classes [ HH.ClassName "swap-on h-10 w-10 fill-current" ] ] [ onHTML ]
        , HH.div [ HP.classes [ HH.ClassName "swap-off h-10 w-10 fill-current" ] ] [ offHTML ]
        ]
    ]

swap_ ::
  forall error action slots m.
  H.ComponentHTML action slots m ->
  H.ComponentHTML action slots m ->
  Checkbox error action ->
  H.ComponentHTML action slots m
swap_ onText offText = flip (swap onText offText) []

swapUpDown :: forall error action slots m. Checkbox error action -> H.ComponentHTML action slots m
swapUpDown = swap_ (upSvgIcon) (downSvgIcon)

swapActiveFinal :: forall error action slots m. Checkbox error action -> H.ComponentHTML action slots m
swapActiveFinal = swap_ (activeSvgIcon) (finalSvgIcon)

-- ==============================================================================
-- TOOLTIP
-- ==============================================================================
setToolTip ∷ ∀ w i. String → HH.HTML w i → HH.HTML w i
setToolTip tooltip html =
  HH.div
    [ HP.classes [ HH.ClassName "tooltip" ]
    , HP.attr (HH.AttrName "data-tip") tooltip
    ]
    [ html ]

setToolTipLeft ∷ ∀ w i. String → HH.HTML w i → HH.HTML w i
setToolTipLeft tooltip html =
  HH.div
    [ HP.classes [ HH.ClassName "tooltip tooltip-left" ]
    , HP.attr (HH.AttrName "data-tip") tooltip
    ]
    [ html ]

setToolTipBottom ∷ ∀ w i. String → HH.HTML w i → HH.HTML w i
setToolTipBottom tooltip html =
  HH.div
    [ HP.classes [ HH.ClassName "tooltip tooltip-bottom" ]
    , HP.attr (HH.AttrName "data-tip") tooltip
    ]
    [ html ]

setToolTipRight ∷ ∀ w i. String → HH.HTML w i → HH.HTML w i
setToolTipRight tooltip html =
  HH.div
    [ HP.classes [ HH.ClassName "tooltip tooltip-right" ]
    , HP.attr (HH.AttrName "data-tip") tooltip
    ]
    [ html ]

-- ==============================================================================
-- MODAL
-- ==============================================================================
-- <button class="btn" onclick="my_modal_1.showModal()">open modal</button>
-- <dialog id="my_modal_1" class="modal">
--   <div class="modal-box">
--     <h3 class="text-lg font-bold">Hello!</h3>
--     <p class="py-4">Press ESC key or click the button below to close</p>
--     <div class="modal-action">
--       <form method="dialog">
--         <!-- if there is a button in form, it will close the modal -->
--         <button class="btn">Close</button>
--       </form>
--     </div>
--   </div>
-- </dialog>
-- JavaScript Interop to call showModal
renderModal :: forall w i. String -> String -> i -> HH.HTML w i -> HH.HTML w i
renderModal = renderModal' "primary"

renderModal' :: forall w i. String -> String -> String -> i -> HH.HTML w i -> HH.HTML w i
renderModal' buttonType modalId buttonName action modalContent =
  HH.div [ HP.classes [] ]
    [ HH.button
        [ HP.classes [ HH.ClassName $ "btn btn-" <> buttonType ], HE.onClick \_ -> action ]
        [ HH.text $ buttonName ]
    , HH.dialog
        [ HP.id modalId
        , HP.classes [ HH.ClassName "modal bg-base-300 text-base-content" ]
        ]
        [ HH.div [ HP.classes [ HH.ClassName "modal-box  w-11/12 max-w-5xl" ] ]
            [ modalContent
            -- , HH.div [ HP.classes [ HH.ClassName "flex justify-end" ] ] [ HH.text "Press ESC key to cancel !" ]
            , HH.div [ HP.classes [ HH.ClassName "modal-action" ] ]
                [ HH.form [ HP.attr (HH.AttrName "method") "dialog" ] [ HH.button_ [ HH.text "Close" ] ] ]
            ]
        ]
    ]

-- ==============================================================================
-- TOAST
-- ==============================================================================
-- <div class="toast toast-top toast-end">
--   <div class="alert alert-info">
--     <span>New mail arrived.</span>
--   </div>
--   <div class="alert alert-success">
--     <span>Message sent successfully.</span>
--   </div>
-- </div>
renderToasts :: forall w i. Array (Tuple String String) -> HH.HTML w i
renderToasts toasts = HH.div [ HP.classes [ HH.ClassName "toast toast-center toast-top z-[9999]" ] ] (renderToast <$> toasts)

renderToast ∷ forall w i. Tuple String String -> HH.HTML w i
renderToast (Tuple alertType message) =
  HH.div [ HP.classes [ HH.ClassName ("alert alert-" <> alertType) ] ]
    [ case alertType of
        "success" -> successSvgIcon
        "error" -> errorSvgIcon
        "warning" -> warningSvgIcon
        _ -> infoSvgIcon
    , HH.span_ [ HH.text message ]
    ]

------------------------------------
------------------------------------
renderImage :: forall w i. String -> HH.HTML w i
renderImage imageUrl =
  HH.figure_
    [ HH.img
        [ HP.classes [ HH.ClassName "rounded-xl" ]
        , HP.src imageUrl
        , HP.width 600
        , HP.height 600
        , HP.alt "Some image"
        -- , HP.attr (HH.AttrName "loading") "lazy"
        ]
    ]

renderDevider :: forall w i. String -> HH.HTML w i
renderDevider deviderType = HH.div [ HP.classes [ HH.ClassName $ "divider divider-" <> deviderType ] ] []

-- <div class="collapse collapse-arrow bg-base-200">
--   <input type="radio" name="my-accordion-2" checked="checked" />
--   <div class="collapse-title text-xl font-medium">Click to open this one and close others</div>
--   <div class="collapse-content">
--     <p>hello</p>
--   </div>
-- </div>
renderAccordionElement :: forall w i. String -> Boolean -> Boolean -> String -> HH.HTML w i -> HH.HTML w i
renderAccordionElement accordionId isChecked overflow title content =
  HH.div [ HP.classes [ HH.ClassName $ "collapse collapse-arrow " <> (if overflow then " relative overflow-visible " else "") ] ]
    [ HH.input [ HP.name accordionId, HP.type_ HP.InputRadio, HP.checked isChecked ]
    , HH.div [ HP.classes [ HH.ClassName "collapse-title text-xl font-medium" ] ]
        [ HH.p_ [ HH.text title ]
        ]
    , HH.div [ HP.classes [ HH.ClassName "collapse-content" ] ]
        [ content ]
    ]

-- ==============================================================================
-- Loading
-- ==============================================================================
renderAccentButtonLoadingSpinner ∷ ∀ w i. String → HH.HTML w i
renderAccentButtonLoadingSpinner text =
  HH.button
    [ HP.classes [ HH.ClassName "btn btn-accent" ] ]
    [ HH.span [ HP.classes [ HH.ClassName "loading loading-spinner" ] ] []
    , HH.text $ text
    ]

renderAccentLoadingSpinner ∷ ∀ w i. String → HH.HTML w i
renderAccentLoadingSpinner text =
  HH.div [ HP.classes [ HH.ClassName "flex justify-center" ] ]
    [ HH.div [ HP.classes [ HH.ClassName "text-accent" ] ]
        [ HH.text $ text
        , HH.span [ HP.classes [ HH.ClassName "loading loading-ring loading-lg text-accent" ] ] []
        ]
    ]

renderAccentLoadingBars ∷ ∀ w i. String → HH.HTML w i
renderAccentLoadingBars text =
  HH.div [ HP.classes [ HH.ClassName "flex justify-center" ] ]
    [ HH.div [ HP.classes [ HH.ClassName "grid grid-cols-1 gap-1 text-accent" ] ]
        [ HH.text $ text
        , HH.span [ HP.classes [ HH.ClassName "loading loading-bars loading-lg text-accent " ] ] []
        ]
    ]

-- ==============================================================================
-- Button
-- ==============================================================================
renderButton ∷ ∀ w i. String -> String → i -> HH.HTML w i
renderButton classes text action =
  HH.button
    ([ HP.classes [ HH.ClassName ("btn " <> classes) ], HE.onClick (\_ -> action) ])
    [ HH.text text ]

renderSecondaryButton ∷ ∀ w i. String → i -> HH.HTML w i
renderSecondaryButton = renderButton "btn-secondary"

renderPrimaryButton ∷ ∀ w i. String → i -> HH.HTML w i
renderPrimaryButton = renderButton "btn-primary"

-- <button class="btn">
--   Button
--   <svg
--     xmlns="http://www.w3.org/2000/svg"
--     class="h-6 w-6"
--     fill="none"
--     viewBox="0 0 24 24"
--     stroke="currentColor">
--     <path
--       stroke-linecap="round"
--       stroke-linejoin="round"
--       stroke-width="2"
--       d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
--   </svg>
-- </button>
-- ==============================================================================
-- STATS
-- ==============================================================================
-- <div class="stat">
--     <div class="stat-figure text-secondary">
--       <div class="avatar online">
--         <div class="w-16 rounded-full">
--           <img src="https://img.daisyui.com/images/stock/photo-1534528741775-53994a69daeb.webp" />
--         </div>
--       </div>
--     </div>
--     <div class="stat-value">86%</div>
--     <div class="stat-title">Tasks done</div>
--     <div class="stat-desc text-secondary">31 tasks remaining</div>
--   </div>
renderStatItemWithFig ∷ forall w i. String -> String -> String -> HH.HTML w i
renderStatItemWithFig fig title desc =
  HH.div [ HP.classes [ HH.ClassName "stats-shadow w-full" ] ]
    [ HH.div [ HP.classes [ HH.ClassName "stat-figure" ] ]
        [ HH.div
            [ HP.classes [ HH.ClassName "mask mask-circle w-16" ] ]
            [ HH.img [ HP.src fig ] ]
        ]
    , HH.div [ HP.classes [ HH.ClassName "stat-title" ] ] [ HH.text title ]
    , HH.div [ HP.classes [ HH.ClassName "stat-desc" ] ] [ HH.text desc ]
    ]

renderStatItem ∷ forall w i. String -> String -> String -> HH.HTML w i
renderStatItem title value desc =
  HH.div [ HP.classes [ HH.ClassName "stats-shadow w-full" ] ]
    [ HH.div [ HP.classes [ HH.ClassName "stat-title" ] ] [ HH.text title ]
    , HH.div [ HP.classes [ HH.ClassName "stat-desc" ] ] [ HH.text desc ]
    , HH.div [ HP.classes [ HH.ClassName "stat-value" ] ] [ HH.text value ]
    ]

renderStats ∷ forall w i. (Array (HH.HTML w i)) -> HH.HTML w i
renderStats stats = HH.div [ HP.classes [ HH.ClassName "stats stats-vertical shadow gap-2 w-full" ] ] stats

------------------------
-- Table
------------------------
renderTable ∷ forall w i. Array String → Array (Array String) → HH.HTML w i
renderTable columns contents =
  HH.div [ HP.classes [ HH.ClassName "overflow-x-auto" ] ]
    [ HH.table [ HP.classes [ HH.ClassName "table" ] ]
        [ HH.thead [] [ HH.tr [] (mapToTH columns) ]
        , HH.tbody [] ((\c -> HH.tr [] (mapToTD c)) <$> contents)
        ]
    ]

mapToTH :: forall w i. Array String -> Array (HH.HTML w i)
mapToTH strings = map (\s -> HH.th [] [ HH.text s ]) strings

mapToTD :: forall w i. Array String -> Array (HH.HTML w i)
mapToTD strings = map (\s -> HH.td [] [ HH.text s ]) strings

------------------------
-- Carousel
------------------------
-- <div class="carousel carousel-center bg-neutral rounded-box max-w-md space-x-4 p-4">
--   <div class="carousel-item">
--     <img
--       src="https://img.daisyui.com/images/stock/photo-1559703248-dcaaec9fab78.webp"
--       class="rounded-box" />
--   </div>
-- </div>
renderCarousel ∷ forall w i. Array (HH.HTML w i) -> HH.HTML w i
renderCarousel elements =
  HH.div [ HP.classes [ HH.ClassName "carousel carousel-center bg-base-300 rounded-box max-w-md space-x-4 p-4" ] ]
    [ HH.div [ HP.classes [ HH.ClassName "carousel-item" ] ]
        elements
    ]

------------------------
-- Card with image overlay
------------------------
-- <div class="card bg-base-100 image-full w-96 shadow-sm">
--   <figure>
--     <img
--       src="https://img.daisyui.com/images/stock/photo-1606107557195-0e29a4b5b4aa.webp"
--       alt="Shoes" />
--   </figure>
--   <div class="card-body">
--     <h2 class="card-title">Card Title</h2>
--     <p>A card component has a figure, a body part, and inside body there are title and actions parts</p>
--     <div class="card-actions justify-end">
--       <button class="btn btn-primary">Buy Now</button>
--     </div>
--   </div>
-- </div>
renderCardWithOverlayImg ∷ forall w i. String -> Array (HH.HTML w i) -> HH.HTML w i
renderCardWithOverlayImg imageUrl elements =
  HH.div [ HP.classes [ HH.ClassName "card bg-base-200 image-full w-80 shadow-lg rounded-box max-w-md space-x-2 p-2" ] ]
    [ HH.figure_ [ renderImage imageUrl ]
    , HH.div [ HP.classes [ HH.ClassName "card-body place-content-center max-w-80 " ] ]
        [ HH.div [ HP.classes [ HH.ClassName "stat" ] ] elements ]
    ]

renderCardWithOverlayImgSingle ∷ forall w i. String -> Array (HH.HTML w i) -> Array (HH.HTML w i) -> HH.HTML w i
renderCardWithOverlayImgSingle imageUrl elements actions =
  HH.div [ HP.classes [ HH.ClassName "card bg-base-200 image-full shadow-lg rounded-box max-w-md space-x-2 p-2" ] ]
    [ HH.figure_ [ HH.img [ HP.src imageUrl ] ]
    , HH.div [ HP.classes [ HH.ClassName "card-body place-content-center" ] ]
        $ [ (HH.div [ HP.classes [ HH.ClassName "stat" ] ] elements) ]
        <> [ HH.div [ HP.classes [ HH.ClassName "card-actions justify-end" ] ]
              actions
          ]
    ]

renderCardWithOverlayImg2 ∷ forall w i. String -> Array (HH.HTML w i) -> Array (HH.HTML w i) -> HH.HTML w i
renderCardWithOverlayImg2 imageUrl elements actions =
  HH.div [ HP.classes [ HH.ClassName "mask mask-squircle card bg-base-200 image-full shadow-lg rounded-box max-w-md space-x-2 p-2" ] ]
    [ HH.figure_ [ HH.img [ HP.src imageUrl ] ]
    , HH.div [ HP.classes [ HH.ClassName "card-body place-content-between " ] ]
        $ elements
        <> [ HH.div [ HP.classes [ HH.ClassName "card-actions justify-end" ] ]
              actions
          ]
    ]

------------------------
-- Horizontal separator
------------------------
-- <div class="flex w-full flex-col lg:flex-row">
--   <div class="card bg-base-300 rounded-box grid h-32 flex-grow place-items-center">content</div>
--   <div class="divider lg:divider-horizontal">OR</div>
--   <div class="card bg-base-300 rounded-box grid h-32 flex-grow place-items-center">content</div>
-- </div>
renderHorizontalDevider ∷ forall w i. HH.HTML w i -> HH.HTML w i -> String -> HH.HTML w i
renderHorizontalDevider contentLeft contentRight text =
  HH.div [ HP.classes [ HH.ClassName "flex flex-row w-full justify-around" ] ]
    [ contentLeft
    , HH.div [ HP.classes [ HH.ClassName "divider divider lg:divider-horizontal grow-0" ] ] [ HH.text text ]
    , contentRight
    ]

renderVerticalDevider ∷ forall w i. HH.HTML w i -> HH.HTML w i -> String -> HH.HTML w i
renderVerticalDevider contentLeft contentRight text =
  HH.div [ HP.classes [ HH.ClassName "flex flex-col w-full justify-around" ] ]
    [ contentLeft
    , HH.div [ HP.classes [ HH.ClassName "divider divider lg:divider-vertical grow-0" ] ] [ HH.text text ]
    , contentRight
    ]

-- <footer class="footer bg-base-200 text-base-content p-10">
--   <aside>
--     <svg
--       width="50"
--       height="50"
--       viewBox="0 0 24 24"
--       xmlns="http://www.w3.org/2000/svg"
--       fill-rule="evenodd"
--       clip-rule="evenodd"
--       class="fill-current">
--       <path
--         d="M22.672 15.226l-2.432.811.841 2.515c.33 1.019-.209 2.127-1.23 2.456-1.15.325-2.148-.321-2.463-1.226l-.84-2.518-5.013 1.677.84 2.517c.391 1.203-.434 2.542-1.831 2.542-.88 0-1.601-.564-1.86-1.314l-.842-2.516-2.431.809c-1.135.328-2.145-.317-2.463-1.229-.329-1.018.211-2.127 1.231-2.456l2.432-.809-1.621-4.823-2.432.808c-1.355.384-2.558-.59-2.558-1.839 0-.817.509-1.582 1.327-1.846l2.433-.809-.842-2.515c-.33-1.02.211-2.129 1.232-2.458 1.02-.329 2.13.209 2.461 1.229l.842 2.515 5.011-1.677-.839-2.517c-.403-1.238.484-2.553 1.843-2.553.819 0 1.585.509 1.85 1.326l.841 2.517 2.431-.81c1.02-.33 2.131.211 2.461 1.229.332 1.018-.21 2.126-1.23 2.456l-2.433.809 1.622 4.823 2.433-.809c1.242-.401 2.557.484 2.557 1.838 0 .819-.51 1.583-1.328 1.847m-8.992-6.428l-5.01 1.675 1.619 4.828 5.011-1.674-1.62-4.829z"></path>
--     </svg>
--     <p>
--       ACME Industries Ltd.
--       <br />
--       Providing reliable tech since 1992
--     </p>
--   </aside>
--   <nav>
--     <h6 class="footer-title">Services</h6>
--     <a class="link link-hover">Branding</a>
--     <a class="link link-hover">Design</a>
--     <a class="link link-hover">Marketing</a>
--     <a class="link link-hover">Advertisement</a>
--   </nav>
--   <nav>
--     <h6 class="footer-title">Company</h6>
--     <a class="link link-hover">About us</a>
--     <a class="link link-hover">Contact</a>
--     <a class="link link-hover">Jobs</a>
--     <a class="link link-hover">Press kit</a>
--   </nav>
--   <nav>
--     <h6 class="footer-title">Legal</h6>
--     <a class="link link-hover">Terms of use</a>
--     <a class="link link-hover">Privacy policy</a>
--     <a class="link link-hover">Cookie policy</a>
--   </nav>
-- </footer>
-- renderFooter :: HH.HTML w i -> Array (Tuple String (Array String)) -> HH.HTML w i
renderLink :: forall w i. String -> String -> String -> HH.HTML w i
renderLink classes title link = HH.a [ HP.classes [ HH.ClassName $ "link " <> classes ], HP.target "_blank", HP.href link ] [ HH.text title ]

renderLinkHover :: forall w i. String -> String -> HH.HTML w i
renderLinkHover = renderLink "link-hover"

renderFooterNav :: forall w i. String -> Array (HH.HTML w i) -> HH.HTML w i
renderFooterNav title contents =
  HH.nav_
    $ [ HH.h6 [ HP.classes [ HH.ClassName "footer-title" ] ] [ HH.text title ]
      ]
    <> contents

renderFooter :: forall w i. HH.HTML w i -> Array (HH.HTML w i) -> HH.HTML w i
renderFooter aside navs =
  HH.footer [ HP.classes [ HH.ClassName "footer md:footer-horizontal bg-neutral text-neutral-content p-10" ] ]
    $ [ aside ]
    <> navs

stringLimitBy :: Int -> String -> String
stringLimitBy limit content =
  if length content > limit then
    (take limit $ content) <> "..."
  else
    content

-- <form class="filter">
--   <input class="btn btn-square" type="reset" value="×"/>
--   <input class="btn" type="radio" name="frameworks" aria-label="Svelte"/>
--   <input class="btn" type="radio" name="frameworks" aria-label="Vue"/>
--   <input class="btn" type="radio" name="frameworks" aria-label="React"/>
-- </form>
renderFilter :: forall w i. String -> Array String -> HH.HTML w i
renderFilter name options =
  HH.form [ HP.classes [ HH.ClassName "filter" ] ]
    $ [ HH.input [ HP.classes [ HH.ClassName "btn btn-square" ], HP.type_ HP.InputReset, HP.value "×" ] ]
    <> ( map
          ( \o ->
              HH.label_
                [ HH.input
                    [ HP.classes [ HH.ClassName "btn" ]
                    , HP.type_ HP.InputRadio
                    , HP.name name
                    , HP.attr (HH.AttrName "aria-label") o
                    ]
                ]
          )
          options
      )

-- ==============================================================================
-- FILTER
-- ==============================================================================
type Filter error action
  = { label :: String
    , options :: Array String
    , state :: F.FieldState String error String
    , action :: F.FieldAction action String error String
    }

-- <div class="filter">
--   <input class="btn filter-reset" type="radio" name="metaframeworks" aria-label="All"/>
--   <input class="btn" type="radio" name="metaframeworks" aria-label="Sveltekit"/>
--   <input class="btn" type="radio" name="metaframeworks" aria-label="Nuxt"/>
--   <input class="btn" type="radio" name="metaframeworks" aria-label="Next.js"/>
-- </div>
filter ::
  forall error action slots m.
  Filter error action ->
  Array (HP.IProp HTMLinput action) ->
  H.ComponentHTML action slots m
filter { label, options, state, action } props =
  HH.fieldset_
    [ HH.label_
        [ HH.text label
        , HH.div [ HP.classes [ HH.ClassName "filter" ] ]
            $ [ HH.input
                  [ HP.classes [ HH.ClassName "btn filter-reset" ]
                  , HP.type_ HP.InputRadio
                  , HP.name label
                  , HP.checked (state.value == "")
                  , HE.onChange (\_ -> action.handleChange "")
                  , HP.attr (HH.AttrName "aria-label") "x"
                  ]
              ]
            <> ( map
                  ( \o ->
                      HH.input
                        $ flip append props
                            [ HP.classes [ HH.ClassName "btn" ]
                            , HP.type_ HP.InputRadio
                            , HP.name label
                            , HP.checked (state.value == o)
                            , HE.onValueInput action.handleChange
                            , HE.onChange (\_ -> action.handleChange o)
                            , HE.onBlur action.handleBlur
                            , HP.attr (HH.AttrName "aria-label") o
                            ]
                  )
                  options
              )
        ]
    ]

filter_ ::
  forall error action slots m.
  Filter error action ->
  H.ComponentHTML action slots m
filter_ = flip filter []

-- ==============================================================================
-- PROFESSIONAL SERVICES (Static Section)
-- ==============================================================================
renderProfessionalServicesSection :: forall w i. HH.HTML w i
renderProfessionalServicesSection =
  HH.section
    [ HP.id "services"
    , HP.classes [ HH.ClassName "w-full max-w-6xl mx-auto px-4 py-12" ]
    ]
    [ HH.div [ HP.classes [ HH.ClassName "text-center mb-8" ] ]
        [ HH.h2 [ HP.classes [ HH.ClassName "text-3xl md:text-4xl font-bold" ] ] [ HH.text "Professional Services" ]
        , HH.p [ HP.classes [ HH.ClassName "opacity-80 mt-2" ] ]
            [ HH.text "We build reliable Web3 apps and infrastructure. From operations to full-stack dApp development, we focus on security, performance, and developer experience."
            ]
        , HH.div [ HP.classes [ HH.ClassName "flex flex-wrap justify-center gap-2 mt-4" ] ]
            [ badge "badge-secondary" "Fixed budget"
            , badge "badge-secondary" "Team augmentation"
            , badge "badge-secondary" "Time and materials"
            ]
        ]
    , HH.div [ HP.classes [ HH.ClassName "grid grid-cols-1 md:grid-cols-2 gap-4" ] ]
        [ serviceCard "Smart Contracts"
            [ "Efficiency and Security"
            , "NFTs, DeFi, you name it"
            ]
        , serviceCard "Audits"
            [ "Expert auditing of your contracts"
            , "Improve security and performance"
            , "Manual and automated testing"
            ]
        , serviceCard "Backend & Frontend"
            [ "Scalable backend for growth"
            , "Engaging and functional UIs"
            , "Security and privacy compliance"
            ]
        , serviceCard "Infrastructure"
            [ "Robust, scalable, and secure"
            , "High availability & data redundancy"
            , "Optimize for peak performance"
            ]
        ]
    , HH.div [ HP.classes [ HH.ClassName "mt-8 flex justify-center" ] ]
        [ HH.a
            [ HP.classes [ HH.ClassName "btn btn-primary" ]
            , HP.href "#contact"
            ]
            [ HH.text "Let's talk" ]
        ]
    ]
  where
  badge :: forall w' i'. String -> String -> HH.HTML w' i'
  badge cls label = HH.div [ HP.classes [ HH.ClassName ("badge " <> cls) ] ] [ HH.text label ]

  serviceCard :: forall w' i'. String -> Array String -> HH.HTML w' i'
  serviceCard title items =
    HH.div [ HP.classes [ HH.ClassName "card bg-base-200 shadow" ] ]
      [ HH.div [ HP.classes [ HH.ClassName "card-body" ] ]
          [ HH.h3 [ HP.classes [ HH.ClassName "card-title text-xl" ] ] [ HH.text title ]
          , HH.ul [ HP.classes [ HH.ClassName "list-disc list-inside opacity-90" ] ]
              (items <#> (\t -> HH.li_ [ HH.text t ]))
          ]
      ]

-- ==============================================================================
-- HERO (Static Section)
-- ==============================================================================
renderHeroSection :: forall w i. HH.HTML w i
renderHeroSection =
  HH.section
    [ HP.id "hero"
    , HP.classes [ HH.ClassName "w-full bg-base-200" ]
    ]
    [ HH.div [ HP.classes [ HH.ClassName "hero min-h-[48vh]" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "hero-content flex-col lg:flex-row gap-8" ] ]
            [ HH.img
                [ HP.src "./images/E7D/SVG Vector Files/Transparent Logo.svg"
                , HP.alt "ENTANGLED Labs Logo"
                , HP.classes [ HH.ClassName "max-w-xs" ]
                ]
            , HH.div_
                [ HH.h1 [ HP.classes [ HH.ClassName "text-4xl md:text-5xl font-bold" ] ] [ HH.text "ENTANGLED Labs" ]
                , HH.p [ HP.classes [ HH.ClassName "py-4 opacity-80" ] ]
                    [ HH.text "Blockchain R&D • Node operators • Professional Services" ]
                , HH.div [ HP.classes [ HH.ClassName "flex gap-2" ] ]
                    [ HH.a
                        [ HP.classes [ HH.ClassName "btn btn-primary" ]
                        , HP.href "https://cexplorer.io/pool/pool1sj3gnahsms73uxxu43rgwczdw596en7dtsfcqf6297vzgcedquv"
                        , HP.target "_blank"
                        ]
                        [ HH.text "Stake with E7D" ]
                    , HH.a
                        [ HP.classes [ HH.ClassName "btn btn-secondary" ]
                        , HP.href "#services"
                        ]
                        [ HH.text "Professional Services" ]
                    ]
                ]
            ]
        ]
    ]

-- ==============================================================================
-- POOL OVERVIEW (Static Section)
-- ==============================================================================
renderPoolOverviewSection :: forall w i. HH.HTML w i
renderPoolOverviewSection =
  HH.section
    [ HP.id "pool"
    , HP.classes [ HH.ClassName "w-full max-w-6xl mx-auto px-4 py-12" ]
    ]
    [ HH.div [ HP.classes [ HH.ClassName "text-center mb-6" ] ]
        [ HH.h2 [ HP.classes [ HH.ClassName "text-3xl font-bold" ] ] [ HH.text "E7D Cardano Staking Pool" ]
        , HH.p [ HP.classes [ HH.ClassName "opacity-80 mt-2" ] ]
            [ HH.text
                "Secure, reliable, and community-focused staking."
            , HH.br_
            , HH.text "We are also a single stake pool operator and are dedicated to providing secure and reliable staking services to our delegators"
            ]
        ]
    , HH.div [ HP.classes [ HH.ClassName "grid grid-cols-1 md:grid-cols-3 gap-4" ] ]
        [ stat "99.9%" "Uptime target"
        , stat "Low fees" "Low fees for our delegators"
        , stat "Secured" "Best practices operations"
        ]
    , HH.div [ HP.classes [ HH.ClassName "mt-6 flex justify-center gap-2" ] ]
        [ HH.a
            [ HP.classes [ HH.ClassName "btn btn-primary" ]
            , HP.href "https://cexplorer.io/pool/pool1sj3gnahsms73uxxu43rgwczdw596en7dtsfcqf6297vzgcedquv"
            , HP.target "_blank"
            ]
            [ HH.text "View Live Metrics" ]
        , HH.a
            [ HP.classes [ HH.ClassName "btn" ]
            , HP.href "#hero"
            ]
            [ HH.text "Delegate Now" ]
        ]
    ]
  where
  stat :: forall w' i'. String -> String -> HH.HTML w' i'
  stat value desc =
    HH.div [ HP.classes [ HH.ClassName "card bg-base-200 shadow" ] ]
      [ HH.div [ HP.classes [ HH.ClassName "card-body items-center text-center" ] ]
          [ HH.div [ HP.classes [ HH.ClassName "text-4xl font-bold" ] ] [ HH.text value ]
          , HH.div [ HP.classes [ HH.ClassName "opacity-80" ] ] [ HH.text desc ]
          ]
      ]

-- ==============================================================================
-- FOOTER (Static Section)
-- ==============================================================================
renderFooterSection :: forall w i. HH.HTML w i
renderFooterSection =
  HH.footer [ HP.classes [ HH.ClassName "footer footer-horizontal  bg-base-200 text-base-content p-10 mt-12" ] ]
    [ HH.aside_
        [ HH.img [ HP.src "./images/E7D/PNG Logo Files/Transparent Logo.png", HP.alt "ENTANGLED Labs", HP.classes [ HH.ClassName "w-16" ] ]
        , HH.p_
            [ HH.text "ENTANGLED Labs"
            , HH.br_
            , HH.text "Reliable Cardano staking and dApp engineering"
            ]
        ]
    , HH.nav_
        [ HH.h6 [ HP.classes [ HH.ClassName "footer-title" ] ] [ HH.text "Company" ]
        , HH.a [ HP.classes [ HH.ClassName "link link-hover" ], HP.href "#about" ] [ HH.text "About" ]
        , HH.a [ HP.classes [ HH.ClassName "link link-hover" ], HP.href "#services" ] [ HH.text "Services" ]
        , HH.a [ HP.classes [ HH.ClassName "link link-hover" ], HP.href "#pool" ] [ HH.text "Pool" ]
        ]
    , HH.nav_
        [ HH.h6 [ HP.classes [ HH.ClassName "footer-title" ] ] [ HH.text "Social" ]
        , HH.a [ HP.classes [ HH.ClassName "link link-hover" ], HP.target "_blank", HP.href "#" ] [ HH.text "Twitter" ]
        , HH.a [ HP.classes [ HH.ClassName "link link-hover" ], HP.target "_blank", HP.href "#" ] [ HH.text "LinkedIn" ]
        , HH.a [ HP.classes [ HH.ClassName "link link-hover" ], HP.target "_blank", HP.href "#" ] [ HH.text "YouTube" ]
        ]
    ]

-- ==============================================================================
-- CEXPLORER POOL GRAPH (Static Section)
-- ==============================================================================
renderCexplorerPoolGraphSection :: forall w i. HH.HTML w i
renderCexplorerPoolGraphSection =
  HH.section
    [ HP.classes [ HH.ClassName "w-full max-w-6xl mx-auto px-4 py-12" ] ]
    [ HH.div [ HP.classes [ HH.ClassName "text-center mb-6" ] ]
        [ HH.h2 [ HP.classes [ HH.ClassName "text-2xl md:text-3xl font-bold" ] ] [ HH.text "Stake Pool Graph" ]
        , HH.p [ HP.classes [ HH.ClassName "opacity-80 mt-2" ] ] [ HH.text "Live metrics via cexplorer.io" ]
        ]
    , HH.div [ HP.classes [ HH.ClassName "flex justify-center" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "w-full max-w-4xl" ] ]
            [ HH.div
                [ HP.classes [ HH.ClassName "relative w-full" ]
                , HP.style "padding-top: 52.8%" -- 530x280 ≈ 1.89 ratio => 52.8% height
                ]
                [ HH.iframe
                    [ HP.src "https://img.cexplorer.io/w/widget-graph.html?pool=pool1sj3gnahsms73uxxu43rgwczdw596en7dtsfcqf6297vzgcedquv&theme=dark"
                    , HP.attr (HH.AttrName "frameborder") "0"
                    , HP.attr (HH.AttrName "allowtransparency") "true"
                    , HP.attr (HH.AttrName "style") "position:absolute;top:0;left:0;width:100%;height:100%;background:transparent !important;"
                    ]
                ]
            ]
        ]
    , HH.div [ HP.classes [ HH.ClassName "text-center mt-3" ] ]
        [ HH.a
            [ HP.href "https://cexplorer.io/pool/pool1sj3gnahsms73uxxu43rgwczdw596en7dtsfcqf6297vzgcedquv"
            , HP.target "_blank"
            , HP.classes [ HH.ClassName "link link-hover" ]
            ]
            [ HH.text "pool detail on cexplorer.io" ]
        ]
    ]
