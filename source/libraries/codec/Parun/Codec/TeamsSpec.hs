module Parun.Codec.TeamsSpec where

import qualified Data.Map.Strict as Map
import qualified Parun.Codec.Teams as Teams
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.TeamId as TeamId
import qualified Parun.Types.Teams as Teams

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Teams" $ do
  -- CR 102.4: a game that is not played between teams.
  Spec.it s "no teams" $
    Common.assertCodec
      s
      Teams.codec
      Teams.none
      " {} "

  -- CR 808.1: two teams of two.
  Spec.it s "two teams of two" $
    Common.assertCodec
      s
      Teams.codec
      ( Teams.MkTeams
          ( Map.fromList
              [ (PlayerId.MkPlayerId 0, TeamId.MkTeamId 0),
                (PlayerId.MkPlayerId 1, TeamId.MkTeamId 1),
                (PlayerId.MkPlayerId 2, TeamId.MkTeamId 0),
                (PlayerId.MkPlayerId 3, TeamId.MkTeamId 1)
              ]
          )
      )
      " {\"0\":0,\"1\":1,\"2\":0,\"3\":1} "

  Spec.it s "has a schema" $
    Common.assertHasSchema s Teams.codec
