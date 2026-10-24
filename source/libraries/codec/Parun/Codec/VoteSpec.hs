module Parun.Codec.VoteSpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Text as Text
import qualified Parun.Codec.Vote as Vote
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Vote as Vote
import qualified Parun.Types.VoteChoices as VoteChoices
import qualified Parun.Types.VoteObjects as VoteObjects
import qualified Parun.Types.VotePlayers as VotePlayers

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Vote" $ do
  -- CR 701.38a: the starter is the seat the vote begins with, and rule 701.38b's
  -- listed choices are the tagged half. Parun.Codec.VoteChoices,
  -- Parun.Codec.VoteObjects and Parun.Codec.VotePlayers have no spec of their
  -- own; these cases are it.
  Spec.it s "MkVote, Council's Judgment's object vote" $
    Common.assertCodec
      s
      Vote.codec
      ( Vote.MkVote
          { Vote.starter = PlayerRef.Relative PlayerRelation.You,
            Vote.choices =
              VoteChoices.Objects
                VoteObjects.MkVoteObjects
                  { VoteObjects.filter = Filter.HasCardType CardType.Creature,
                    VoteObjects.slot = SlotName.MkSlotName (Text.pack "elected")
                  },
            Vote.secret = False
          }
      )
      " {\"starter\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"choices\":{\"type\":\"Objects\",\"value\":{\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"slot\":\"elected\"}}} "
  Spec.it s "MkVote, Plea for Power's word vote" $
    Common.assertCodec
      s
      Vote.codec
      ( Vote.MkVote
          { Vote.starter = PlayerRef.Relative PlayerRelation.You,
            Vote.choices =
              VoteChoices.Words
                ( SlotName.MkSlotName (Text.pack "time")
                    NonEmpty.:| [SlotName.MkSlotName (Text.pack "knowledge")]
                ),
            Vote.secret = False
          }
      )
      " {\"starter\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"choices\":{\"type\":\"Words\",\"value\":[\"time\",\"knowledge\"]}} "
  -- Secret council (CR 207.2c): the one vote written with the key.
  Spec.it s "MkVote, Truth or Consequences' secret word vote" $
    Common.assertCodec
      s
      Vote.codec
      ( Vote.MkVote
          { Vote.starter = PlayerRef.Relative PlayerRelation.You,
            Vote.choices =
              VoteChoices.Words
                ( SlotName.MkSlotName (Text.pack "truth")
                    NonEmpty.:| [SlotName.MkSlotName (Text.pack "consequences")]
                ),
            Vote.secret = True
          }
      )
      " {\"starter\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"choices\":{\"type\":\"Words\",\"value\":[\"truth\",\"consequences\"]},\"secret\":true} "
  -- CR 701.38b's players, Mob Verdict's secret "another player" vote.
  Spec.it s "MkVote, Mob Verdict's secret player vote" $
    Common.assertCodec
      s
      Vote.codec
      ( Vote.MkVote
          { Vote.starter = PlayerRef.Relative PlayerRelation.You,
            Vote.choices = VoteChoices.Players VotePlayers.MkVotePlayers {VotePlayers.another = True, VotePlayers.slot = SlotName.MkSlotName (Text.pack "votes")},
            Vote.secret = True
          }
      )
      " {\"starter\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"choices\":{\"type\":\"Players\",\"value\":{\"another\":true,\"slot\":\"votes\"}},\"secret\":true} "
  -- Círdan the Shipwright's "votes for a player", which may be oneself.
  Spec.it s "MkVote, a player vote open to every player" $
    Common.assertCodec
      s
      Vote.codec
      ( Vote.MkVote
          { Vote.starter = PlayerRef.Relative PlayerRelation.You,
            Vote.choices = VoteChoices.Players VotePlayers.MkVotePlayers {VotePlayers.another = False, VotePlayers.slot = SlotName.MkSlotName (Text.pack "votes")},
            Vote.secret = False
          }
      )
      " {\"starter\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"choices\":{\"type\":\"Players\",\"value\":{\"slot\":\"votes\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Vote.codec
