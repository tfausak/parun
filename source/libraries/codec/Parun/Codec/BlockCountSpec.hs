module Parun.Codec.BlockCountSpec where

import qualified Parun.Codec.BlockCount as BlockCount
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BlockCount as BlockCount
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.BlockCount" $ do
  Spec.it s "Once" $
    Common.assertCodec s BlockCount.codec BlockCount.Once " {\"type\":\"Once\"} "
  -- Loyal Sentry's "blocks a creature".
  Spec.it s "EachCreature" $
    Common.assertCodec
      s
      BlockCount.codec
      (BlockCount.EachCreature (Filter.And []))
      " {\"type\":\"EachCreature\",\"value\":{\"type\":\"And\",\"value\":[]}} "
  -- Lairwatch Giant's "two or more creatures": any creature writes no key.
  Spec.it s "AtLeast, any creature" $
    Common.assertCodec
      s
      BlockCount.codec
      (BlockCount.AtLeast 2 (Filter.And []))
      " {\"type\":\"AtLeast\",\"value\":{\"floor\":2}} "
  -- Serra Inquisitors' "one or more black creatures".
  Spec.it s "AtLeast, a Filter" $
    Common.assertCodec
      s
      BlockCount.codec
      (BlockCount.AtLeast 1 (Filter.HasColor Color.Black))
      " {\"type\":\"AtLeast\",\"value\":{\"floor\":1,\"others\":{\"type\":\"HasColor\",\"value\":{\"type\":\"Black\"}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s BlockCount.codec
