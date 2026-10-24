{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CausedBy where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CausedBy as CausedBy

-- | A bare object keyed by the record's field names, the condition written with
-- whichever codec its parameter takes.
codec :: (Typeable.Typeable condition) => Codec.Codec condition -> Codec.Codec (CausedBy.CausedBy condition)
codec condition = Fields.object $ do
  controller <- Fields.required "controller" PlayerRelation.codec CausedBy.controller
  narrowed <- Fields.required "condition" condition CausedBy.condition
  pure CausedBy.MkCausedBy {CausedBy.controller = controller, CausedBy.condition = narrowed}
