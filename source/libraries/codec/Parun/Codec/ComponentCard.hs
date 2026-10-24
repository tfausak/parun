{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ComponentCard where

import qualified Parun.Codec.CardIdentity as CardIdentity
import qualified Parun.Codec.PrintingId as PrintingId
import qualified Parun.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ComponentCard as ComponentCard

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
