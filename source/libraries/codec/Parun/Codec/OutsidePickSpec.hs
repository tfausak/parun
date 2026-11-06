module Parun.Codec.OutsidePickSpec where

import qualified Parun.Codec.OutsidePick as OutsidePick
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.OutsidePick as OutsidePick
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.OutsidePick" $ do
  Spec.it s "MkOutsidePick" $
    Common.assertCodec
      s
      OutsidePick.codec
      (OutsidePick.MkOutsidePick PlayerRelation.Opponent 1)
      " {\"chooser\":\"Opponent\",\"count\":1} "
  Spec.it s "has a schema" $ Common.assertHasSchema s OutsidePick.codec
