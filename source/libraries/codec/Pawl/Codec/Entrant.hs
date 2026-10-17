{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.Entrant where

import qualified Pawl.Codec.Label as Label
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Entrant as Entrant

codec :: Codec.Codec Entrant.Entrant
codec = Fields.object $ do
  name <- Fields.required "name" Label.codec Entrant.name
  deck <- Fields.required "deck" (Common.list Common.text) Entrant.deck
  pure Entrant.MkEntrant {Entrant.name = name, Entrant.deck = deck}
