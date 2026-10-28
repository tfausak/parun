{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ActivationsThisTurn where

import qualified Parun.Codec.ActivationCriteria as ActivationCriteria
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ActivationsThisTurn as ActivationsThisTurn

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec ActivationsThisTurn.ActivationsThisTurn
codec = Fields.object $ do
  activator <- Fields.required "activator" PlayerRef.codec ActivationsThisTurn.activator
  source <- Fields.required "source" (Filter.codec Keyword.codec) ActivationsThisTurn.source
  criteria <- Fields.required "criteria" ActivationCriteria.codec ActivationsThisTurn.criteria
  pure ActivationsThisTurn.MkActivationsThisTurn {ActivationsThisTurn.activator = activator, ActivationsThisTurn.source = source, ActivationsThisTurn.criteria = criteria}
