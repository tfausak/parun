{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ComponentCard where

import qualified Pawl.Codec.CardIdentity as CardIdentity
import qualified Pawl.Codec.PrintingId as PrintingId
import qualified Pawl.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ComponentCard as ComponentCard

codec :: Codec.Codec ComponentCard.ComponentCard
codec = Fields.object $ do
  printing <- Fields.required "printing" PrintingId.codec ComponentCard.printing
  identity <- Fields.defaulted "identity" Nothing (Common.maybe CardIdentity.codec) ComponentCard.identity
  duplicate <- Fields.defaulted "duplicate" Nothing (Common.maybe ProjectedCharacteristics.codec) ComponentCard.duplicate
  pure
    ComponentCard.MkComponentCard
      { ComponentCard.printing = printing,
        ComponentCard.identity = identity,
        ComponentCard.duplicate = duplicate
      }
