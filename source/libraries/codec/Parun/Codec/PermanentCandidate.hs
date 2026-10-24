{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PermanentCandidate where

import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.InstanceOrdinal as InstanceOrdinal
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.ReplacementEffect as ReplacementEffect
import qualified Parun.Codec.ReplacementProvenance as ReplacementProvenance
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PermanentCandidate as PermanentCandidate

-- | The effect codec is built from the card codec the same way every other
-- parameterized codec in this library is.
codec :: Codec.Codec PermanentCandidate.PermanentCandidate
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec PermanentCandidate.source
  provenance <- Fields.required "provenance" ReplacementProvenance.codec PermanentCandidate.provenance
  effect <- Fields.required "effect" (ReplacementEffect.codec Card.codec (GrantedAbility.codec Card.codec) (Effect.codec Card.codec (GrantedAbility.codec Card.codec))) PermanentCandidate.effect
  ordinal <- Fields.required "ordinal" InstanceOrdinal.codec PermanentCandidate.ordinal
  pure
    PermanentCandidate.MkPermanentCandidate
      { PermanentCandidate.source = source,
        PermanentCandidate.provenance = provenance,
        PermanentCandidate.effect = effect,
        PermanentCandidate.ordinal = ordinal
      }
