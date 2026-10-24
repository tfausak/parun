module Parun.Codec.VoteChoices where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.Codec.VoteObjects as VoteObjects
import qualified Parun.Codec.VotePlayers as VotePlayers
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.VoteChoices as VoteChoices

codec :: Codec.Codec VoteChoices.VoteChoices
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Objects" VoteObjects.codec VoteChoices.Objects (\x -> case x of VoteChoices.Objects y -> Just y; _ -> Nothing),
      Arm.payload "Words" (Common.nonEmpty SlotName.codec) VoteChoices.Words (\x -> case x of VoteChoices.Words y -> Just y; _ -> Nothing),
      Arm.payload "Players" VotePlayers.codec VoteChoices.Players (\x -> case x of VoteChoices.Players y -> Just y; _ -> Nothing)
    ]

tagOf :: VoteChoices.VoteChoices -> String
tagOf x = case x of
  VoteChoices.Objects {} -> "Objects"
  VoteChoices.Words {} -> "Words"
  VoteChoices.Players {} -> "Players"
