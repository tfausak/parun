{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ActivationProhibition where

import qualified Parun.Codec.AbilityKind as AbilityKind
import qualified Parun.Codec.AbilityName as AbilityName
import qualified Parun.Codec.Affected as Affected
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ActivationProhibition as ActivationProhibition

-- | An object with two named keys, Parun.Codec.CounterRestriction's shape with a
-- CR 605.1a ability kind where that one has a counter kind. Untagged for that
-- codec's reason: Parun.Types.ActivationProhibition is a product with no sum for
-- a tag to discriminate.
--
-- "affected" is REQUIRED and both "kind" and "name" DEFAULT to Nothing, the
-- asymmetry that codec argues: a missing affected set has no defensible default -- the empty
-- one disarms the prohibition and the full one widens it to the whole board --
-- while a missing kind is exactly what Arrest prints, a prohibition naming no
-- kind at all.
codec :: Codec.Codec ActivationProhibition.ActivationProhibition
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec ActivationProhibition.affected
  kind <- Fields.defaulted "kind" Nothing (Common.maybe AbilityKind.codec) ActivationProhibition.kind
  name <- Fields.defaulted "name" Nothing (Common.maybe AbilityName.codec) ActivationProhibition.name
  pure
    ActivationProhibition.MkActivationProhibition
      { ActivationProhibition.affected = affected,
        ActivationProhibition.kind = kind,
        ActivationProhibition.name = name
      }
