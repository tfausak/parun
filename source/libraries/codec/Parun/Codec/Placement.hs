{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Placement where

import qualified Data.Map.Strict as Map
import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.FaceDownReason as FaceDownReason
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Label as Label
import qualified Parun.Codec.Readiness as Readiness
import qualified Parun.Codec.TapState as TapState
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Placement as Placement
import qualified Parun.Types.Readiness as Readiness.Type
import qualified Parun.Types.TapState as TapState.Type

codec :: Codec.Codec Placement.Placement
codec = Fields.object $ do
  card <- Fields.required "card" CardName.codec Placement.card
  label <- Fields.defaulted "label" Nothing (Common.maybe Label.codec) Placement.label
  tapped <- Fields.defaulted "tapped" TapState.Type.Untapped TapState.flag Placement.tapped
  readiness <- Fields.defaulted "ready" Readiness.Type.Sick Readiness.codec Placement.readiness
  damage <- Fields.defaulted "damage" 0 Common.natural Placement.damage
  counters <- Fields.defaulted "counters" Map.empty (Common.multiset (CounterKind.codec Keyword.codec)) Placement.counters
  token <- Fields.defaulted "token" False Common.boolean Placement.token
  controller <- Fields.defaulted "controller" Nothing (Common.maybe Label.codec) Placement.controller
  attached <- Fields.defaulted "attached" Nothing (Common.maybe Label.codec) Placement.attached
  commander <- Fields.defaulted "commander" False Common.boolean Placement.commander
  face <- Fields.defaulted "face" Nothing (Common.maybe CardName.codec) Placement.face
  faceDown <- Fields.defaulted "faceDown" Nothing (Common.maybe FaceDownReason.codec) Placement.faceDown
  protector <- Fields.defaulted "protector" Nothing (Common.maybe Label.codec) Placement.protector
  pure
    Placement.MkPlacement
      { Placement.card = card,
        Placement.label = label,
        Placement.tapped = tapped,
        Placement.readiness = readiness,
        Placement.damage = damage,
        Placement.counters = counters,
        Placement.token = token,
        Placement.controller = controller,
        Placement.attached = attached,
        Placement.commander = commander,
        Placement.face = face,
        Placement.faceDown = faceDown,
        Placement.protector = protector
      }
