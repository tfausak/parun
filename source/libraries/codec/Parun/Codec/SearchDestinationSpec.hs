module Parun.Codec.SearchDestinationSpec where

import qualified Parun.Codec.SearchDestination as SearchDestination
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.SearchDestination as SearchDestination

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SearchDestination" $ do
  Spec.it s "Battlefield" $
    Common.assertCodec
      s
      SearchDestination.codec
      SearchDestination.Battlefield
      " \"Battlefield\" "
  Spec.it s "BattlefieldTapped" $
    Common.assertCodec
      s
      SearchDestination.codec
      SearchDestination.BattlefieldTapped
      " \"BattlefieldTapped\" "
  Spec.it s "RevealThenHand" $
    Common.assertCodec
      s
      SearchDestination.codec
      SearchDestination.RevealThenHand
      " \"RevealThenHand\" "
  Spec.it s "Exile" $
    Common.assertCodec
      s
      SearchDestination.codec
      SearchDestination.Exile
      " \"Exile\" "
  Spec.it s "BattlefieldAttachedOrHand" $
    Common.assertCodec
      s
      SearchDestination.codec
      SearchDestination.BattlefieldAttachedOrHand
      " \"BattlefieldAttachedOrHand\" "
  Spec.it s "BattlefieldAttached" $
    Common.assertCodec
      s
      SearchDestination.codec
      SearchDestination.BattlefieldAttached
      " \"BattlefieldAttached\" "
  Spec.it s "Reveal" $
    Common.assertCodec
      s
      SearchDestination.codec
      SearchDestination.Reveal
      " \"Reveal\" "
  Spec.it s "Stay" $
    Common.assertCodec
      s
      SearchDestination.codec
      SearchDestination.Stay
      " \"Stay\" "
  Spec.it s "RevealThenTop" $
    Common.assertCodec
      s
      SearchDestination.codec
      SearchDestination.RevealThenTop
      " \"RevealThenTop\" "
  Spec.it s "Top" $
    Common.assertCodec
      s
      SearchDestination.codec
      SearchDestination.Top
      " \"Top\" "
  Spec.it s "Hand" $
    Common.assertCodec
      s
      SearchDestination.codec
      SearchDestination.Hand
      " \"Hand\" "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s SearchDestination.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s SearchDestination.codec
