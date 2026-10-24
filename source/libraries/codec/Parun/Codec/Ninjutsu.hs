{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Ninjutsu where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.NinjutsuVariant as NinjutsuVariant
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Ninjutsu as Ninjutsu

-- | A bare object keyed by the record's field names. The keyword codec is a
-- PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Ninjutsu.Ninjutsu keyword)
codec keywordCodec = Fields.object $ do
  cost <- Fields.required "cost" (Cost.codec keywordCodec) Ninjutsu.cost
  variant <- Fields.required "variant" NinjutsuVariant.codec Ninjutsu.variant
  pure Ninjutsu.MkNinjutsu {Ninjutsu.cost = cost, Ninjutsu.variant = variant}
