module Parun.Codec.RequireBlockSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.RequireBlock as RequireBlock
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.RequireBlock as RequireBlock
import qualified Parun.Types.RequirementArity as RequirementArity
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RequireBlock" $ do
  -- CR 509.1c. BOTH sides name an ObjectRef, so the fixture names them
  -- differently on purpose: only an asymmetric case catches a codec that pointed
  -- the requirement the wrong way.
  Spec.it s "MkRequireBlock, every key" $
    Common.assertCodec
      s
      RequireBlock.codec
      ( RequireBlock.MkRequireBlock
          { RequireBlock.duration = Duration.UntilEndOfTurn,
            RequireBlock.blocker = RestrictedCreatures.Named (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "blocker"))),
            RequireBlock.attacker = Just (RestrictedCreatures.Named (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "attacker")))),
            RequireBlock.arity = RequirementArity.AnySubject
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"blocker\":{\"type\":\"Named\",\"value\":{\"type\":\"InSlot\",\"value\":\"blocker\"}},\"attacker\":{\"type\":\"Named\",\"value\":{\"type\":\"InSlot\",\"value\":\"attacker\"}},\"arity\":{\"type\":\"AnySubject\"}} "
  -- Both defaults, no attacker and EachSubject, are omitted.
  Spec.it s "MkRequireBlock, defaults omitted" $
    Common.assertCodec
      s
      RequireBlock.codec
      ( RequireBlock.MkRequireBlock
          { RequireBlock.duration = Duration.UntilEndOfTurn,
            RequireBlock.blocker = RestrictedCreatures.Named (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "blocker"))),
            RequireBlock.attacker = Nothing,
            RequireBlock.arity = RequirementArity.EachSubject
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"blocker\":{\"type\":\"Named\",\"value\":{\"type\":\"InSlot\",\"value\":\"blocker\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s RequireBlock.codec
