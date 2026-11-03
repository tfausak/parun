{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.NextDamageInstance where

import qualified Data.Sequence as Seq
import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.NextDamageOutcome as NextDamageOutcome
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.NextDamageInstance as NextDamageInstance
import qualified Parun.Types.NextDamageOutcome as NextDamageOutcome.Type

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PreventAllDamage writes the unbounded shield's.
--
-- The effect codec is a PARAMETER rather than an import, for
-- Parun.Codec.PreventNextDamage's reason.
--
-- @chosenSource@ is 'Fields.defaulted' to the trivial predicate, which is what
-- "a source of your choice" says on every printing of this rule; @ref@ and
-- @duration@ are required, both being fields the type does not make optional.
codec ::
  (Typeable.Typeable effect, Eq effect) =>
  Codec.Codec effect ->
  Codec.Codec (NextDamageInstance.NextDamageInstance effect)
codec effectCodec = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec NextDamageInstance.duration
  ref <- Fields.required "ref" ObjectRef.codec NextDamageInstance.ref
  chosenSource <- Fields.defaulted "chosenSource" (Filter.And []) (Filter.codec Keyword.codec) NextDamageInstance.chosenSource
  riders <- Fields.defaulted "riders" Seq.empty (Common.seq effectCodec) NextDamageInstance.riders
  outcome <- Fields.defaulted "outcome" NextDamageOutcome.Type.Prevented NextDamageOutcome.codec NextDamageInstance.outcome
  pure
    NextDamageInstance.MkNextDamageInstance
      { NextDamageInstance.duration = duration,
        NextDamageInstance.ref = ref,
        NextDamageInstance.chosenSource = chosenSource,
        NextDamageInstance.riders = riders,
        NextDamageInstance.outcome = outcome
      }
