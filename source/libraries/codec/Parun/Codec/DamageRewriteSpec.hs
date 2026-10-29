module Parun.Codec.DamageRewriteSpec where

import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.DamageRewrite as DamageRewrite
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DamageRewrite as DamageRewrite
import qualified Parun.Types.Destroy as Destroy
import qualified Parun.Types.Effect as Effect.Type
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Regenerability as Regenerability
import qualified Parun.Types.Scaling as Scaling
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DamageRewrite" $ do
  Spec.it s "PreventAll" $
    Common.assertCodec
      s
      (DamageRewrite.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      DamageRewrite.PreventAll
      " {\"type\":\"PreventAll\"} "
  -- CR 122.1c's prevention half. Minted from a permanent's shield counters and
  -- never authored on a card, so this codec is the only place its wire form is
  -- pinned.
  Spec.it s "PreventRemovingShieldCounter" $
    Common.assertCodec
      s
      (DamageRewrite.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      DamageRewrite.PreventRemovingShieldCounter
      " {\"type\":\"PreventRemovingShieldCounter\"} "
  -- CR 615.7's shield, whose Natural is what REMAINS of it. Baked by Resolve's
  -- PreventNextDamage arm and never authored on a card, so this codec is the
  -- only place the wire form is pinned.
  Spec.it s "PreventNext" $
    Common.assertCodec
      s
      (DamageRewrite.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      (DamageRewrite.PreventNext 4)
      " {\"type\":\"PreventNext\",\"value\":4} "
  -- CR 615.10's static shield, whose Natural is what SURVIVES it -- the one
  -- Temple Altisaur prints.
  Spec.it s "PreventAllBut" $
    Common.assertCodec
      s
      (DamageRewrite.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      (DamageRewrite.PreventAllBut 1)
      " {\"type\":\"PreventAllBut\",\"value\":1} "
  -- CR 702.64a's ceiling, the arm above read from the other end: the amount is
  -- what is PREVENTED rather than what survives. A Quantity, read at each event
  -- (Shield of the Avatar's count); absorb's is a literal.
  Spec.it s "PreventUpTo" $
    Common.assertCodec
      s
      (DamageRewrite.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      (DamageRewrite.PreventUpTo (Quantity.Literal 1))
      " {\"type\":\"PreventUpTo\",\"value\":{\"type\":\"Literal\",\"value\":1}} "
  -- CR 614.1a: a flat instead-amount.
  Spec.it s "SetAmount" $
    Common.assertCodec
      s
      (DamageRewrite.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      (DamageRewrite.SetAmount 4)
      " {\"type\":\"SetAmount\",\"value\":4} "
  -- A doubling, which is Scaling's Multiply 2.
  Spec.it s "Scale" $
    Common.assertCodec
      s
      (DamageRewrite.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      (DamageRewrite.Scale (Scaling.Multiply 2))
      " {\"type\":\"Scale\",\"value\":{\"type\":\"Multiply\",\"value\":2}} "
  -- CR 614.9's redirection. Baked by Resolve's RedirectDamage arm and never
  -- authored on a card -- card data cannot name an ObjectId -- so this codec is
  -- the replay path's, not a card's.
  Spec.it s "Redirect" $
    Common.assertCodec
      s
      (DamageRewrite.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      (DamageRewrite.Redirect (Recipient.ToCreature (ObjectId.MkObjectId 7)))
      " {\"type\":\"Redirect\",\"value\":{\"type\":\"ToCreature\",\"value\":7}} "
  -- Redirect with CR 615.7's countdown (Harm's Way), keyed by name for #1464's
  -- reason; the replay path's, as Redirect's is.
  Spec.it s "RedirectNext" $
    Common.assertCodec
      s
      (DamageRewrite.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      (DamageRewrite.RedirectNext 2 (Recipient.ToCreature (ObjectId.MkObjectId 7)))
      " {\"type\":\"RedirectNext\",\"value\":{\"remaining\":2,\"to\":{\"type\":\"ToCreature\",\"value\":7}}} "
  -- CR 614.9's redirection with a PRINTED destination (Pariah's "dealt to
  -- enchanted creature instead"). The authored twin of Redirect above, so this
  -- wire form IS a card's.
  Spec.it s "RedirectMatching" $
    Common.assertCodec
      s
      (DamageRewrite.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      (DamageRewrite.RedirectMatching Filter.IsHostOfSource)
      " {\"type\":\"RedirectMatching\",\"value\":{\"type\":\"IsHostOfSource\"}} "
  -- CR 614.1a: the rewrite that runs an effect in the damage's place --
  -- Kill-Suit Cultist's "destroy that creature instead", over the slot its own
  -- ability targeted.
  Spec.it s "RunEffects (Kill-Suit Cultist)" $
    Common.assertCodec
      s
      (DamageRewrite.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      (DamageRewrite.RunEffects (Seq.fromList [Effect.Type.Destroy (Destroy.MkDestroy (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "creature"))) Regenerability.Regenerable Nothing Nothing Nothing)]))
      " {\"type\":\"RunEffects\",\"value\":[{\"type\":\"Destroy\",\"value\":{\"ref\":{\"type\":\"InSlot\",\"value\":\"creature\"},\"regenerability\":{\"type\":\"Regenerable\"}}}]} "
  Spec.it s "TurnFaceUp" $
    Common.assertCodec
      s
      (DamageRewrite.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      DamageRewrite.TurnFaceUp
      " {\"type\":\"TurnFaceUp\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (DamageRewrite.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
