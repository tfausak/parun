{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExileHaunting where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExileHaunting as ExileHaunting

-- | A bare object keyed by the record's field names. Naming them is the point:
-- both are a SlotName, so a positional payload would let a card file swap the
-- haunting card and its host and still decode.
codec :: Codec.Codec ExileHaunting.ExileHaunting
codec = Fields.object $ do
  card <- Fields.required "card" SlotName.codec ExileHaunting.card
  host <- Fields.required "host" SlotName.codec ExileHaunting.host
  pure
    ExileHaunting.MkExileHaunting
      { ExileHaunting.card = card,
        ExileHaunting.host = host
      }
