module Parun.Codec.BlocksDeclaredSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.BlocksDeclared as BlocksDeclared
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BlocksDeclared as BlocksDeclared
import qualified Parun.Types.ObjectId as ObjectId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.BlocksDeclared" $ do
  -- CR 509.1i read the other way: the attackers one creature blocked.
  Spec.it s "MkBlocksDeclared, both keys" $
    Common.assertCodec
      s
      BlocksDeclared.codec
      (BlocksDeclared.MkBlocksDeclared {BlocksDeclared.blocker = ObjectId.MkObjectId 1, BlocksDeclared.blocked = Set.fromList [ObjectId.MkObjectId 2, ObjectId.MkObjectId 3]})
      " {\"blocker\":1,\"blocked\":[2,3]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s BlocksDeclared.codec
