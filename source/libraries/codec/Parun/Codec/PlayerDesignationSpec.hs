module Parun.Codec.PlayerDesignationSpec where

import qualified Parun.Codec.PlayerDesignation as PlayerDesignation
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerDesignation as PlayerDesignation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerDesignation" $ do
  Spec.it s "CitysBlessing" $
    Common.assertCodec
      s
      PlayerDesignation.codec
      PlayerDesignation.CitysBlessing
      " {\"type\":\"CitysBlessing\"} "
  Spec.it s "EnduringStory" $
    Common.assertCodec
      s
      PlayerDesignation.codec
      PlayerDesignation.EnduringStory
      " {\"type\":\"EnduringStory\"} "
  -- Parun.Codec.DesignationSpec's closing case, and for its reason: Arm.enum
  -- derives the arm list from the type, so this is what would catch a
  -- constructor the derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s PlayerDesignation.codec
