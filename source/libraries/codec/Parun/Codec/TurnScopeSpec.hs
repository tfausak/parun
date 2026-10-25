module Parun.Codec.TurnScopeSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.TurnScope as TurnScope
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TurnScope as TurnScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TurnScope" $ do
  Spec.it s "EachTurn" $
    Common.assertCodec
      s
      TurnScope.codec
      TurnScope.EachTurn
      " {\"type\":\"EachTurn\"} "
  Spec.it s "ControllersTurn" $
    Common.assertCodec
      s
      TurnScope.codec
      TurnScope.ControllersTurn
      " {\"type\":\"ControllersTurn\"} "
  Spec.it s "OpponentsTurn" $
    Common.assertCodec
      s
      TurnScope.codec
      TurnScope.OpponentsTurn
      " {\"type\":\"OpponentsTurn\"} "
  Spec.it s "PlayersTurn" $
    Common.assertCodec
      s
      TurnScope.codec
      (TurnScope.PlayersTurn (PlayerRef.ControllerOfHostOfBound (SlotName.MkSlotName (Text.pack "self"))))
      " {\"type\":\"PlayersTurn\",\"value\":{\"type\":\"ControllerOfHostOfBound\",\"value\":\"self\"}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s TurnScope.codec
