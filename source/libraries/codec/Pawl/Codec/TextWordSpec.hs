module Pawl.Codec.TextWordSpec where

import qualified Data.List as List
import qualified Data.Set as Set
import qualified Pawl.Codec.TextWord as TextWord
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.Subtype as Subtype
import qualified Pawl.Types.TextWord as TextWord

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.TextWord" $ do
  Spec.it s "ColorWord" $
    Common.assertCodec
      s
      TextWord.codec
      (TextWord.ColorWord Color.Black)
      " {\"type\":\"Black\"} "
  Spec.it s "SubtypeWord" $
    Common.assertCodec
      s
      TextWord.codec
      (TextWord.SubtypeWord Subtype.Island)
      " {\"type\":\"Island\"} "
  -- The untagged wire rests on no colour sharing a spelling with a subtype, so
  -- every word of both families must decode back to itself.
  Spec.it s "round trips every word" $ do
    let words_ = fmap TextWord.ColorWord [minBound ..] <> fmap TextWord.SubtypeWord [minBound ..]
        tags = fmap TextWord.tagOf words_
    Spec.assertEqWith s "every tag is distinct" (length tags) (Set.size (Set.fromList tags))
    Spec.assertEqWith s "every word decodes to itself" [] (List.filter (\w -> Codec.decode TextWord.codec (Codec.encode TextWord.codec w) /= Right w) words_)
  Spec.it s "has a schema" $
    Common.assertHasSchema s TextWord.codec
