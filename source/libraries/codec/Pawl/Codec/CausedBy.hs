{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.CausedBy where

import qualified Data.Typeable as Typeable
import qualified Pawl.Codec.PlayerRelation as PlayerRelation
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.CausedBy as CausedBy

-- | A bare object keyed by the record's field names, the condition written with
-- whichever codec its parameter takes.
codec :: (Typeable.Typeable condition) => Codec.Codec condition -> Codec.Codec (CausedBy.CausedBy condition)
codec condition = Fields.object $ do
  controller <- Fields.required "controller" PlayerRelation.codec CausedBy.controller
  narrowed <- Fields.required "condition" condition CausedBy.condition
  pure CausedBy.MkCausedBy {CausedBy.controller = controller, CausedBy.condition = narrowed}
