{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayersWho where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayersWho as PlayersWho

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.ObjectRef's Players arm. @who@ is omitted when absent,
-- every printing but Disorder's naming its players unnarrowed.
codec :: Codec.Codec PlayersWho.PlayersWho
codec = Fields.object $ do
  players <- Fields.required "players" PlayerRef.codec PlayersWho.players
  who <- Fields.defaulted "who" Nothing (Common.maybe (Filter.codec Keyword.codec)) PlayersWho.who
  pure PlayersWho.MkPlayersWho {PlayersWho.players = players, PlayersWho.who = who}
