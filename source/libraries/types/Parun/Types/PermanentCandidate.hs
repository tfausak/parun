module Parun.Types.PermanentCandidate where

import qualified Parun.Types.Card as Card
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.InstanceOrdinal as InstanceOrdinal
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.ReplacementProvenance as ReplacementProvenance

-- | CR 614.5's identity for a permanent's STATIC replacement ability: the
-- source, where the row came from, the effect VALUE, and the ordinal among
-- equals. Parun.Types.CandidateId carries the rule and the reasoning; this is the
-- payload that arm names.
--
-- A record rather than four positional fields, so which of the two ids is the
-- source cannot be got wrong at a construction site, and so the arm has the one
-- payload a codec needs.
--
-- The provenance is part of the IDENTITY and not a note beside it, which is the
-- rule rather than a convenience: a card printing exactly the row rule 702.16e
-- mints for the protection it also has would otherwise collapse the two into one
-- instance, where CR 614.5 gives each its own opportunity.
data PermanentCandidate = MkPermanentCandidate
  { source :: ObjectId.ObjectId,
    provenance :: ReplacementProvenance.ReplacementProvenance,
    effect :: ReplacementEffect.ReplacementEffect Card.Card (GrantedAbility.GrantedAbility Card.Card) (Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)),
    ordinal :: InstanceOrdinal.InstanceOrdinal
  }
  deriving (Eq, Ord, Show)
