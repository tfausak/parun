module Pawl.Codec.VotedSpec where

import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Pawl.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Pawl.Codec.Voted as Voted
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Ballot as Ballot
import qualified Pawl.Types.BallotChoice as BallotChoice
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.ObjectSnapshot as ObjectSnapshot
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.Voted as Voted

-- Pawl.Codec.Ballot and Pawl.Codec.BallotChoice have no spec of their own;
-- these cases, one per choice, are it.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.Voted" $ do
  -- CR 701.38b's object choice, shown to every player in a two-player game.
  Spec.it s "MkVoted, an object ballot" $
    Common.assertCodec
      s
      Voted.codec
      ( Voted.MkVoted
          { Voted.ballot =
              Ballot.MkBallot
                { Ballot.voter = PlayerId.MkPlayerId 1,
                  Ballot.choice =
                    BallotChoice.ForObject
                      ObjectSnapshot.MkObjectSnapshot
                        { ObjectSnapshot.object = ObjectId.MkObjectId 7,
                          ObjectSnapshot.characteristics = ProjectedCharacteristicsSpec.testCharacteristics,
                          ObjectSnapshot.controller = Just (PlayerId.MkPlayerId 0),
                          ObjectSnapshot.owner = PlayerId.MkPlayerId 0
                        }
                },
            Voted.audience = Set.fromList [PlayerId.MkPlayerId 0, PlayerId.MkPlayerId 1]
          }
      )
      ( "{\"ballot\":{\"voter\":1,\"choice\":{\"type\":\"ForObject\",\"value\":{\"object\":7,\"characteristics\":"
          <> ProjectedCharacteristicsSpec.testCharacteristicsJson
          <> ",\"controller\":0,\"owner\":0}}},\"audience\":[0,1]}"
      )
  -- CR 701.38b's word choice, shown to its voter alone.
  Spec.it s "MkVoted, a word ballot" $
    Common.assertCodec
      s
      Voted.codec
      ( Voted.MkVoted
          { Voted.ballot = Ballot.MkBallot {Ballot.voter = PlayerId.MkPlayerId 2, Ballot.choice = BallotChoice.ForWord (SlotName.MkSlotName (Text.pack "truth"))},
            Voted.audience = Set.fromList [PlayerId.MkPlayerId 2]
          }
      )
      "{\"ballot\":{\"voter\":2,\"choice\":{\"type\":\"ForWord\",\"value\":\"truth\"}},\"audience\":[2]}"
  -- CR 701.38b's player choice.
  Spec.it s "MkVoted, a player ballot" $
    Common.assertCodec
      s
      Voted.codec
      ( Voted.MkVoted
          { Voted.ballot = Ballot.MkBallot {Ballot.voter = PlayerId.MkPlayerId 0, Ballot.choice = BallotChoice.ForPlayer (PlayerId.MkPlayerId 2)},
            Voted.audience = Set.fromList [PlayerId.MkPlayerId 0]
          }
      )
      "{\"ballot\":{\"voter\":0,\"choice\":{\"type\":\"ForPlayer\",\"value\":2}},\"audience\":[0]}"
  Spec.it s "has a schema" $ Common.assertHasSchema s Voted.codec
