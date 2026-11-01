module Parun.Codec.ChosenQualitySpec where

import qualified Parun.Codec.ChosenQuality as ChosenQuality
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ChooseBetween as ChooseBetween
import qualified Parun.Types.ChosenQuality as ChosenQuality

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ChosenQuality" $ do
  Spec.it s "Colors (Tablet of the Guilds)" $
    Common.assertCodec
      s
      ChosenQuality.codec
      (ChosenQuality.Colors (ChooseBetween.MkChooseBetween 2 2))
      " {\"type\":\"Colors\",\"value\":{\"least\":2,\"most\":2}} "
  Spec.it s "Colors as a range (Scuttlemutt)" $
    Common.assertCodec
      s
      ChosenQuality.codec
      (ChosenQuality.Colors (ChooseBetween.MkChooseBetween 1 5))
      " {\"type\":\"Colors\",\"value\":{\"least\":1,\"most\":5}} "
  Spec.it s "BasicLandType (Convincing Mirage)" $
    Common.assertCodec
      s
      ChosenQuality.codec
      ChosenQuality.BasicLandType
      " {\"type\":\"BasicLandType\"} "
  Spec.it s "CreatureType (Pillar of Origins)" $
    Common.assertCodec
      s
      ChosenQuality.codec
      ChosenQuality.CreatureType
      " {\"type\":\"CreatureType\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ChosenQuality.codec
