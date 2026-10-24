{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SpendManaAsThough where

import qualified Parun.Codec.ManaFilter as ManaFilter
import qualified Parun.Codec.ManaType as ManaType
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SpendManaAsThough as SpendManaAsThough

-- | A bare object keyed by the record's field names, as every other
-- Parun.Types.PlayerEffect payload is (#1464).
codec :: Codec.Codec SpendManaAsThough.SpendManaAsThough
codec = Fields.object $ do
  which <- Fields.required "which" ManaFilter.codec SpendManaAsThough.which
  asThough <- Fields.required "asThough" (Common.set ManaType.codec) SpendManaAsThough.asThough
  only <- Fields.required "only" Common.boolean SpendManaAsThough.only
  pure
    SpendManaAsThough.MkSpendManaAsThough
      { SpendManaAsThough.which = which,
        SpendManaAsThough.asThough = asThough,
        SpendManaAsThough.only = only
      }
