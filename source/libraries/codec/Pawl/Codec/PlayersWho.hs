{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.PlayersWho where

import qualified Pawl.Codec.Filter as Filter
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.Codec.PlayerRef as PlayerRef
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.PlayersWho as PlayersWho

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Pawl.Codec.ObjectRef's Players arm. @who@ is omitted when absent,
-- every printing but Disorder's naming its players unnarrowed.
codec :: Codec.Codec PlayersWho.PlayersWho
codec = Fields.object $ do
  players <- Fields.required "players" PlayerRef.codec PlayersWho.players
  who <- Fields.defaulted "who" Nothing (Common.maybe (Filter.codec Keyword.codec)) PlayersWho.who
  pure PlayersWho.MkPlayersWho {PlayersWho.players = players, PlayersWho.who = who}
