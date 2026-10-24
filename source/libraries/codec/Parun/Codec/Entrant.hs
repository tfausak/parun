{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Entrant where

import qualified Parun.Codec.Label as Label
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Entrant as Entrant

codec :: Codec.Codec Entrant.Entrant
codec = Fields.object $ do
  name <- Fields.required "name" Label.codec Entrant.name
  deck <- Fields.required "deck" (Common.list Common.text) Entrant.deck
  pure Entrant.MkEntrant {Entrant.name = name, Entrant.deck = deck}
