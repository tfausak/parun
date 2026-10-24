module Parun.Codec.StatedFlipSpec where

import qualified Parun.Codec.StatedFlip as StatedFlip
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CoinFace as CoinFace
import qualified Parun.Types.StatedFlip as StatedFlip

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.StatedFlip" $ do
  -- A statement of neither half, which is what every field defaulting away
  -- encodes to.
  Spec.it s "MkStatedFlip" $
    Common.assertCodec
      s
      StatedFlip.codec
      StatedFlip.MkStatedFlip
        { StatedFlip.face = Nothing,
          StatedFlip.wins = False,
          StatedFlip.firstEachTurn = False
        }
      " {} "
  -- CR 705.3 as Edgar, King of Figaro prints it: both halves, narrowed to the
  -- first flip of the turn.
  Spec.it s "MkStatedFlip stating both halves" $
    Common.assertCodec
      s
      StatedFlip.codec
      StatedFlip.MkStatedFlip
        { StatedFlip.face = Just CoinFace.Heads,
          StatedFlip.wins = True,
          StatedFlip.firstEachTurn = True
        }
      " {\"face\":{\"type\":\"Heads\"},\"wins\":true,\"firstEachTurn\":true} "
  Spec.it s "has a schema" $ Common.assertHasSchema s StatedFlip.codec
