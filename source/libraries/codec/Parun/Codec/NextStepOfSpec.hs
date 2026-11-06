module Parun.Codec.NextStepOfSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.NextStepOf as NextStepOf
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.Hop as Hop
import qualified Parun.Types.NextStepOf as NextStepOf.Type
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.NextStepOf" $ do
  Spec.it s "leaves out you" $
    Common.assertCodec
      s
      NextStepOf.codec
      (NextStepOf.Type.MkNextStepOf (Phase.Beginning BeginningStep.Upkeep) (PlayerRef.Relative PlayerRelation.You))
      " {\"step\":{\"type\":\"Beginning\",\"value\":\"Upkeep\"}} "
  Spec.it s "names any other player" $
    Common.assertCodec
      s
      NextStepOf.codec
      (NextStepOf.Type.MkNextStepOf (Phase.Beginning BeginningStep.Untap) (PlayerRef.HolderOfBound Holder.Controller Hop.Itself (SlotName.MkSlotName (Text.pack "target"))))
      " {\"player\":{\"type\":\"HolderOfBound\",\"value\":{\"holder\":\"Controller\",\"hop\":\"Itself\",\"slot\":\"target\"}},\"step\":{\"type\":\"Beginning\",\"value\":\"Untap\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s NextStepOf.codec
