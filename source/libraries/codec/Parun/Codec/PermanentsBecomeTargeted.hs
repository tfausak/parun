{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PermanentsBecomeTargeted where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.StackObjectKind as StackObjectKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PermanentsBecomeTargeted as PermanentsBecomeTargeted

-- | A bare object keyed by the record's field names. The filter is required,
-- while the kind is elided when absent for Parun.Codec.ControllerBecomesTarget's
-- reason: "a spell or ability" is the wider and unnarrowed reading of CR 601.2c.
codec :: Codec.Codec PermanentsBecomeTargeted.PermanentsBecomeTargeted
codec = Fields.object $ do
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) PermanentsBecomeTargeted.filter
  kind <- Fields.defaulted "kind" Nothing (Common.maybe StackObjectKind.codec) PermanentsBecomeTargeted.kind
  pure
    PermanentsBecomeTargeted.MkPermanentsBecomeTargeted
      { PermanentsBecomeTargeted.filter = filter_,
        PermanentsBecomeTargeted.kind = kind
      }
