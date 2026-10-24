module Parun.Codec.ScopeSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Scope as Scope
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.EventShape as EventShape
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.MovedBetween as MovedBetween
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Scope" $ do
  Spec.it s "InZone" $
    Common.assertCodec
      s
      Scope.codec
      (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer)))
      " {\"type\":\"InZone\",\"value\":{\"zone\":{\"type\":\"Battlefield\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}}}} "
  -- CR 608.2i's look-back-in-time domain.
  Spec.it s "InHistory" $
    Common.assertCodec
      s
      Scope.codec
      (Scope.InHistory (EventShape.MovedBetween (MovedBetween.MkMovedBetween Zone.Battlefield Zone.Graveyard)))
      " {\"type\":\"InHistory\",\"value\":{\"type\":\"MovedBetween\",\"value\":{\"from\":{\"type\":\"Battlefield\"},\"to\":{\"type\":\"Graveyard\"}}}} "
  -- CR 102.1's domain: the players a reference names, rather than their zones.
  Spec.it s "OverPlayers" $
    Common.assertCodec
      s
      Scope.codec
      (Scope.OverPlayers (PlayerRef.Relative PlayerRelation.Opponent))
      " {\"type\":\"OverPlayers\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"Opponent\"}}} "
  -- CR 400.7j's domain: the objects a slot of the surrounding announcement
  -- names, rather than a zone's residents.
  Spec.it s "OverBound" $
    Common.assertCodec
      s
      Scope.codec
      (Scope.OverBound (SlotName.MkSlotName (Text.pack "discarded")))
      " {\"type\":\"OverBound\",\"value\":\"discarded\"} "
  -- CR 404.1's domain: one POSITION in each named graveyard, rather than the
  -- whole pile the InZone arm above reads.
  Spec.it s "TopOfGraveyard" $
    Common.assertCodec
      s
      Scope.codec
      (Scope.TopOfGraveyard (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "player"))))
      " {\"type\":\"TopOfGraveyard\",\"value\":{\"type\":\"InSlot\",\"value\":\"player\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Scope.codec
