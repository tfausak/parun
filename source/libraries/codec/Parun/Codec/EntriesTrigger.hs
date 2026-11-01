{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.EntriesTrigger where

import qualified Parun.Codec.EntryTriggering as EntryTriggering
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EntriesTrigger as EntriesTrigger

codec :: Codec.Codec EntriesTrigger.EntriesTrigger
codec = Fields.object $ do
  entrants <- Fields.required "entrants" (Filter.codec Keyword.codec) EntriesTrigger.entrants
  triggering <- Fields.required "triggering" EntryTriggering.codec EntriesTrigger.triggering
  pure EntriesTrigger.MkEntriesTrigger {EntriesTrigger.entrants = entrants, EntriesTrigger.triggering = triggering}
