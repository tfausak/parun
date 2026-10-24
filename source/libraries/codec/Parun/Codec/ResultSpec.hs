module Parun.Codec.ResultSpec where

import qualified Parun.Codec.Result as Result
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Result as Result
import qualified Parun.Types.TeamId as TeamId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Result" $ do
  -- CR 104.2: the winner is named, so the arm carries a seat.
  Spec.it s "Won" $
    Common.assertCodec
      s
      Result.codec
      (Result.Won (PlayerId.MkPlayerId 1))
      " {\"type\":\"Won\",\"value\":1} "
  -- CR 104.2c: a team wins, named by its team.
  Spec.it s "TeamWon" $
    Common.assertCodec
      s
      Result.codec
      (Result.TeamWon (TeamId.MkTeamId 1))
      " {\"type\":\"TeamWon\",\"value\":1} "
  -- CR 104.4: a draw names nobody.
  Spec.it s "Drawn" $
    Common.assertCodec
      s
      Result.codec
      Result.Drawn
      " {\"type\":\"Drawn\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Result.codec
