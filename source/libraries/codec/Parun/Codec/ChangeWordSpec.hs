module Parun.Codec.ChangeWordSpec where

import qualified Parun.Codec.ChangeWord as ChangeWord
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ChangeWord as ChangeWord
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TextWord as TextWord

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ChangeWord" $ do
  -- CR 612.1, as Artificial Evolution changes one creature type to another. Asymmetric on purpose: a swapped codec would round-trip an equal pair.
  Spec.it s "MkChangeWord" $
    Common.assertCodec
      s
      ChangeWord.codec
      ( ChangeWord.MkChangeWord
          { ChangeWord.from = TextWord.SubtypeWord Subtype.Wall,
            ChangeWord.to = TextWord.SubtypeWord Subtype.Bird
          }
      )
      " {\"from\":{\"type\":\"Wall\"},\"to\":{\"type\":\"Bird\"}} "
  -- CR 612.2's colour word, as Sleight of Mind changes one.
  Spec.it s "MkChangeWord, colour words" $
    Common.assertCodec
      s
      ChangeWord.codec
      ( ChangeWord.MkChangeWord
          { ChangeWord.from = TextWord.ColorWord Color.Black,
            ChangeWord.to = TextWord.ColorWord Color.Blue
          }
      )
      " {\"from\":{\"type\":\"Black\"},\"to\":{\"type\":\"Blue\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ChangeWord.codec
