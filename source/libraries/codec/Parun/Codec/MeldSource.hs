{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.MeldSource where

import qualified Parun.Codec.ComponentCard as ComponentCard
import qualified Parun.Codec.PrintingId as PrintingId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.MeldSource as MeldSource

-- | Common.nonEmpty rejects an empty array, so the wire cannot describe a
-- melded permanent that no card represents.
codec :: Codec.Codec MeldSource.MeldSource
codec = Fields.object $ do
  result <- Fields.required "result" PrintingId.codec MeldSource.result
  components <- Fields.required "components" (Common.nonEmpty ComponentCard.codec) MeldSource.components
  pure
    MeldSource.MkMeldSource
      { MeldSource.result = result,
        MeldSource.components = components
      }
