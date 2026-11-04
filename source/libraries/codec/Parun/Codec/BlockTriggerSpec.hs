module Parun.Codec.BlockTriggerSpec where

import qualified Parun.Codec.BlockTrigger as BlockTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BlockCount as BlockCount
import qualified Parun.Types.BlockRole as BlockRole
import qualified Parun.Types.BlockTrigger as BlockTrigger
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.BlockTrigger" $ do
  -- Pride Guardian's "whenever this creature blocks".
  Spec.it s "the defaults write no key" $
    Common.assertCodec
      s
      BlockTrigger.codec
      (BlockTrigger.MkBlockTrigger BlockRole.Blocker Filter.IsSource BlockCount.Once)
      " {\"role\":{\"type\":\"Blocker\"}} "
  -- Venom's "whenever enchanted creature becomes blocked by a creature".
  Spec.it s "a creature and a count write their keys" $
    Common.assertCodec
      s
      BlockTrigger.codec
      (BlockTrigger.MkBlockTrigger BlockRole.Attacker (Filter.HasAttached Filter.IsSource) (BlockCount.EachCreature (Filter.And [])))
      " {\"role\":{\"type\":\"Attacker\"},\"creature\":{\"type\":\"HasAttached\",\"value\":{\"type\":\"IsSource\"}},\"count\":{\"type\":\"EachCreature\",\"value\":{\"type\":\"And\",\"value\":[]}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s BlockTrigger.codec
