{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.Ninjutsu where

import qualified Data.Typeable as Typeable
import qualified Pawl.Codec.Cost as Cost
import qualified Pawl.Codec.NinjutsuVariant as NinjutsuVariant
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Ninjutsu as Ninjutsu

-- | A bare object keyed by the record's field names. The keyword codec is a
-- PARAMETER; see Pawl.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Ninjutsu.Ninjutsu keyword)
codec keywordCodec = Fields.object $ do
  cost <- Fields.required "cost" (Cost.codec keywordCodec) Ninjutsu.cost
  variant <- Fields.required "variant" NinjutsuVariant.codec Ninjutsu.variant
  pure Ninjutsu.MkNinjutsu {Ninjutsu.cost = cost, Ninjutsu.variant = variant}
