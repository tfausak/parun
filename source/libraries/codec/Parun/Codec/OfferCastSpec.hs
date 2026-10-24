module Parun.Codec.OfferCastSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.CastOffer as CastOffer
import qualified Parun.Codec.OfferCast as OfferCast
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CastObligation as CastObligation
import qualified Parun.Types.CastOffer as CastOffer.Type
import qualified Parun.Types.CastRepetition as CastRepetition
import qualified Parun.Types.ManaSpending as ManaSpending
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.OfferCast as OfferCast
import qualified Parun.Types.PermissionVerb as PermissionVerb
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.OfferCast" $ do
  -- CR 608.2g's bare offer: an ordinary cast of the card, which is the elided
  -- case.
  Spec.it s "MkOfferCast, offer elided" $
    Common.assertCodec
      s
      OfferCast.codec
      ( OfferCast.MkOfferCast
          { OfferCast.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "exiled")),
            OfferCast.caster = PlayerRef.Relative PlayerRelation.You,
            OfferCast.optionality = CastObligation.Optional,
            OfferCast.offer = CastOffer.defaultValue,
            OfferCast.repetition = CastRepetition.Once,
            OfferCast.copied = False,
            OfferCast.verb = PermissionVerb.Cast,
            OfferCast.controlWhileResolving = False,
            OfferCast.slot = Nothing
          }
      )
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"exiled\"}} "
  -- CR 310.12b's two riders, which is what stops the offer being elided.
  Spec.it s "MkOfferCast, offer written" $
    Common.assertCodec
      s
      OfferCast.codec
      ( OfferCast.MkOfferCast
          { OfferCast.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "exiled")),
            OfferCast.caster = PlayerRef.Relative PlayerRelation.You,
            OfferCast.optionality = CastObligation.Optional,
            OfferCast.offer =
              CastOffer.Type.MkCastOffer
                { CastOffer.Type.transformed = True,
                  CastOffer.Type.withoutPayingManaCost = True,
                  CastOffer.Type.payingInstead = Nothing,
                  CastOffer.Type.spending = ManaSpending.AsProduced,
                  CastOffer.Type.restriction = Nothing,
                  CastOffer.Type.offeredBy = Nothing,
                  CastOffer.Type.faceDown = Nothing,
                  CastOffer.Type.payableFromSpent = False,
                  CastOffer.Type.reduction = 0
                },
            OfferCast.repetition = CastRepetition.Once,
            OfferCast.copied = False,
            OfferCast.verb = PermissionVerb.Cast,
            OfferCast.controlWhileResolving = False,
            OfferCast.slot = Nothing
          }
      )
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"exiled\"},\"offer\":{\"transformed\":true,\"withoutPayingManaCost\":true}} "
  -- CR 608.2g's OTHER posture -- "instructs", to a player the effect names.
  -- Wild Evocation's, and the pair of keys nothing else in the pool writes.
  Spec.it s "MkOfferCast, caster and optionality written" $
    Common.assertCodec
      s
      OfferCast.codec
      ( OfferCast.MkOfferCast
          { OfferCast.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "revealed")),
            OfferCast.caster = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "thatPlayer")),
            OfferCast.optionality = CastObligation.Mandatory,
            OfferCast.offer =
              CastOffer.Type.MkCastOffer
                { CastOffer.Type.transformed = False,
                  CastOffer.Type.withoutPayingManaCost = True,
                  CastOffer.Type.payingInstead = Nothing,
                  CastOffer.Type.spending = ManaSpending.AsProduced,
                  CastOffer.Type.restriction = Nothing,
                  CastOffer.Type.offeredBy = Nothing,
                  CastOffer.Type.faceDown = Nothing,
                  CastOffer.Type.payableFromSpent = False,
                  CastOffer.Type.reduction = 0
                },
            OfferCast.repetition = CastRepetition.Once,
            OfferCast.copied = False,
            OfferCast.verb = PermissionVerb.Cast,
            OfferCast.controlWhileResolving = False,
            OfferCast.slot = Nothing
          }
      )
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"revealed\"},\"caster\":{\"type\":\"InSlot\",\"value\":\"thatPlayer\"},\"optionality\":{\"type\":\"Mandatory\"},\"offer\":{\"withoutPayingManaCost\":true}} "
  -- The key a repeated offer writes: Fevered Suspicion's "any number", the one
  -- posture the three cases above all default away from.
  Spec.it s "MkOfferCast, repetition written" $
    Common.assertCodec
      s
      OfferCast.codec
      ( OfferCast.MkOfferCast
          { OfferCast.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "exiled")),
            OfferCast.caster = PlayerRef.Relative PlayerRelation.You,
            OfferCast.optionality = CastObligation.Optional,
            OfferCast.offer = CastOffer.defaultValue,
            OfferCast.repetition = CastRepetition.AnyNumber,
            OfferCast.copied = False,
            OfferCast.verb = PermissionVerb.Cast,
            OfferCast.controlWhileResolving = False,
            OfferCast.slot = Nothing
          }
      )
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"exiled\"},\"repetition\":{\"type\":\"AnyNumber\"}} "
  -- CR 707.12's key, Mizzix's Mastery's "copy it, and you may cast the copy".
  Spec.it s "MkOfferCast, copied written" $
    Common.assertCodec
      s
      OfferCast.codec
      ( OfferCast.MkOfferCast
          { OfferCast.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "exiled")),
            OfferCast.caster = PlayerRef.Relative PlayerRelation.You,
            OfferCast.optionality = CastObligation.Optional,
            OfferCast.offer = CastOffer.defaultValue,
            OfferCast.repetition = CastRepetition.Once,
            OfferCast.copied = True,
            OfferCast.verb = PermissionVerb.Cast,
            OfferCast.controlWhileResolving = False,
            OfferCast.slot = Nothing
          }
      )
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"exiled\"},\"copied\":true} "
  -- CR 400.7h's key, Storm of Memories' "that spell".
  Spec.it s "MkOfferCast, slot written" $
    Common.assertCodec
      s
      OfferCast.codec
      ( OfferCast.MkOfferCast
          { OfferCast.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "exiled")),
            OfferCast.caster = PlayerRef.Relative PlayerRelation.You,
            OfferCast.optionality = CastObligation.Optional,
            OfferCast.offer = CastOffer.defaultValue,
            OfferCast.repetition = CastRepetition.Once,
            OfferCast.copied = False,
            OfferCast.verb = PermissionVerb.Cast,
            OfferCast.controlWhileResolving = False,
            OfferCast.slot = Just (SlotName.MkSlotName (Text.pack "spell"))
          }
      )
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"exiled\"},\"slot\":\"spell\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s OfferCast.codec
