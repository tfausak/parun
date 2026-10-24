module Parun.Codec.RedirectDamageSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.RedirectDamage as RedirectDamage
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BlockStatus as BlockStatus
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RedirectDamage as RedirectDamage
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Uses as Uses

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RedirectDamage" $ do
  -- CR 614.9, Turn the Tables. 'from' and 'to' are both an ObjectRef, so the
  -- fixture names them differently on purpose: only an asymmetric case catches
  -- a codec that sent the damage back the way it came.
  Spec.it s "MkRedirectDamage, kind written" $
    Common.assertCodec
      s
      RedirectDamage.codec
      ( RedirectDamage.MkRedirectDamage
          { RedirectDamage.duration = Duration.UntilEndOfTurn,
            RedirectDamage.kind = Just DamageKind.Combat,
            RedirectDamage.amount = Nothing,
            RedirectDamage.from = Just (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "you"))),
            RedirectDamage.whatRecipient = Nothing,
            RedirectDamage.whoRecipient = Nothing,
            RedirectDamage.to = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "attacker")),
            RedirectDamage.chosenSource = Nothing,
            RedirectDamage.uses = Uses.Unlimited,
            RedirectDamage.whatSource = Filter.And []
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"kind\":{\"type\":\"Combat\"},\"from\":{\"type\":\"InSlot\",\"value\":\"you\"},\"to\":{\"type\":\"InSlot\",\"value\":\"attacker\"}} "
  -- A redirect naming no kind, which is the elided case.
  Spec.it s "MkRedirectDamage, kind elided" $
    Common.assertCodec
      s
      RedirectDamage.codec
      ( RedirectDamage.MkRedirectDamage
          { RedirectDamage.duration = Duration.UntilEndOfTurn,
            RedirectDamage.kind = Nothing,
            RedirectDamage.amount = Nothing,
            RedirectDamage.from = Just (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "you"))),
            RedirectDamage.whatRecipient = Nothing,
            RedirectDamage.whoRecipient = Nothing,
            RedirectDamage.to = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "attacker")),
            RedirectDamage.chosenSource = Nothing,
            RedirectDamage.uses = Uses.Unlimited,
            RedirectDamage.whatSource = Filter.And []
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"from\":{\"type\":\"InSlot\",\"value\":\"you\"},\"to\":{\"type\":\"InSlot\",\"value\":\"attacker\"}} "
  -- Oracle's Attendants: the key is WRITTEN and its Filter is the trivial one,
  -- since the card names no property the chosen source must have. Elided and
  -- present-but-trivial are different redirections -- every source, against the
  -- one the controller chose -- so the round trip has to keep them apart.
  Spec.it s "MkRedirectDamage, CR 609.7a's chosen source" $
    Common.assertCodec
      s
      RedirectDamage.codec
      ( RedirectDamage.MkRedirectDamage
          { RedirectDamage.duration = Duration.UntilEndOfTurn,
            RedirectDamage.kind = Nothing,
            RedirectDamage.amount = Nothing,
            RedirectDamage.from = Just (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target"))),
            RedirectDamage.whatRecipient = Nothing,
            RedirectDamage.whoRecipient = Nothing,
            RedirectDamage.to = ObjectRef.EachMatching Filter.IsSource,
            RedirectDamage.chosenSource = Just (Filter.And []),
            RedirectDamage.uses = Uses.Unlimited,
            RedirectDamage.whatSource = Filter.And []
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"from\":{\"type\":\"InSlot\",\"value\":\"target\"},\"to\":{\"type\":\"EachMatching\",\"value\":{\"type\":\"IsSource\"}},\"chosenSource\":{\"type\":\"And\",\"value\":[]}} "
  -- Harm's Way: CR 615.7's amount and a DESCRIBED recipient side, so `from` is
  -- elided and the description's two halves are written.
  Spec.it s "MkRedirectDamage, counted and described" $
    Common.assertCodec
      s
      RedirectDamage.codec
      ( RedirectDamage.MkRedirectDamage
          { RedirectDamage.duration = Duration.UntilEndOfTurn,
            RedirectDamage.kind = Nothing,
            RedirectDamage.amount = Just (Quantity.Literal 2),
            RedirectDamage.from = Nothing,
            RedirectDamage.whatRecipient = Just (Filter.ControlledBy PlayerRelation.You),
            RedirectDamage.whoRecipient = Just PlayerRelation.You,
            RedirectDamage.to = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target")),
            RedirectDamage.chosenSource = Just (Filter.And []),
            RedirectDamage.uses = Uses.Unlimited,
            RedirectDamage.whatSource = Filter.And []
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"amount\":{\"type\":\"Literal\",\"value\":2},\"whatRecipient\":{\"type\":\"ControlledBy\",\"value\":{\"type\":\"You\"}},\"whoRecipient\":{\"type\":\"You\"},\"to\":{\"type\":\"InSlot\",\"value\":\"target\"},\"chosenSource\":{\"type\":\"And\",\"value\":[]}} "
  -- Jade Monolith's "the next time" and Kjeldoran Royal Guard's "by unblocked
  -- creatures": CR 614.3's use count and CR 609.7b's described source, both
  -- written only when not the default.
  Spec.it s "MkRedirectDamage, once and a described source" $
    Common.assertCodec
      s
      RedirectDamage.codec
      ( RedirectDamage.MkRedirectDamage
          { RedirectDamage.duration = Duration.UntilEndOfTurn,
            RedirectDamage.kind = Nothing,
            RedirectDamage.amount = Nothing,
            RedirectDamage.from = Just (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target"))),
            RedirectDamage.whatRecipient = Nothing,
            RedirectDamage.whoRecipient = Nothing,
            RedirectDamage.to = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "you")),
            RedirectDamage.chosenSource = Nothing,
            RedirectDamage.uses = Uses.Once,
            RedirectDamage.whatSource = Filter.HasBlockStatus BlockStatus.Unblocked
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"from\":{\"type\":\"InSlot\",\"value\":\"target\"},\"to\":{\"type\":\"InSlot\",\"value\":\"you\"},\"uses\":{\"type\":\"Once\"},\"whatSource\":{\"type\":\"HasBlockStatus\",\"value\":{\"type\":\"Unblocked\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s RedirectDamage.codec
