{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PastActivation where

import qualified Parun.Codec.AbilityKind as AbilityKind
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectSnapshot as ObjectSnapshot
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PastActivation as PastActivation

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec PastActivation.PastActivation
codec = Fields.object $ do
  activator <- Fields.required "activator" PlayerId.codec PastActivation.activator
  source <- Fields.required "source" ObjectSnapshot.codec PastActivation.source
  keyword <- Fields.required "keyword" (Common.maybe Keyword.codec) PastActivation.keyword
  kind <- Fields.required "kind" AbilityKind.codec PastActivation.kind
  targets <- Fields.required "targets" (Common.list ObjectSnapshot.codec) PastActivation.targets
  pure
    PastActivation.MkPastActivation
      { PastActivation.activator = activator,
        PastActivation.source = source,
        PastActivation.keyword = keyword,
        PastActivation.kind = kind,
        PastActivation.targets = targets
      }
