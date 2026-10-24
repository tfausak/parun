{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.MoveMana where

import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.MoveMana as MoveMana

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's MoveMana arm.
--
-- `from` is required and does not default: defaulting it to CR 109.5's "you"
-- would make the empty object mean a loss of the caster's own mana. An absent
-- `to` is CR 106.4's plain loss, no one adding the mana.
codec :: Codec.Codec MoveMana.MoveMana
codec = Fields.object $ do
  from <- Fields.required "from" PlayerRef.codec MoveMana.from
  to <- Fields.defaulted "to" Nothing (Common.maybe PlayerRef.codec) MoveMana.to
  pure
    MoveMana.MkMoveMana
      { MoveMana.from = from,
        MoveMana.to = to
      }
