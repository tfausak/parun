{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ObjectView where

import qualified Parun.Codec.AbilityView as AbilityView
import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.Codec.Recipient as Recipient
import qualified Parun.Codec.TapState as TapState
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ObjectView as ObjectView

-- | A bare object keyed by the record's field names; `characteristics` is
-- null for an object the seat may not see, and `face` for any but a face-down
-- one the seat may look at; `ability` is null for anything but an ability on
-- the stack.
codec :: Codec.Codec ObjectView.ObjectView
codec = Fields.object $ do
  object <- Fields.required "object" ObjectId.codec ObjectView.object
  owner <- Fields.required "owner" PlayerId.codec ObjectView.owner
  controller <- Fields.required "controller" (Common.maybe PlayerId.codec) ObjectView.controller
  tapped <- Fields.required "tapped" TapState.flag ObjectView.tapped
  damage <- Fields.required "damage" Common.natural ObjectView.damage
  counters <- Fields.required "counters" (Common.multiset (CounterKind.codec Keyword.codec)) ObjectView.counters
  attachedTo <- Fields.required "attachedTo" (Common.maybe Recipient.codec) ObjectView.attachedTo
  characteristics <- Fields.required "characteristics" (Common.maybe ProjectedCharacteristics.codec) ObjectView.characteristics
  face <- Fields.required "face" (Common.maybe ProjectedCharacteristics.codec) ObjectView.face
  ability <- Fields.required "ability" (Common.maybe AbilityView.codec) ObjectView.ability
  pure
    ObjectView.MkObjectView
      { ObjectView.object = object,
        ObjectView.owner = owner,
        ObjectView.controller = controller,
        ObjectView.tapped = tapped,
        ObjectView.damage = damage,
        ObjectView.counters = counters,
        ObjectView.attachedTo = attachedTo,
        ObjectView.characteristics = characteristics,
        ObjectView.face = face,
        ObjectView.ability = ability
      }
