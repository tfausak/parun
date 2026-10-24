module Parun.Codec.PlayerRelation where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PlayerRelation as PlayerRelation

codec :: Codec.Codec PlayerRelation.PlayerRelation
codec = Arm.enum

-- | The relation's arms as arms of a tagged type that wraps it, under the
-- relation's own tags, so every wrapper (Parun.Codec.ControllerRelation,
-- Parun.Codec.PlayerScope) spells "you", "an opponent" and "any player" the way
-- a filter or a trigger does. Derived from the type, so a new relation reaches
-- every wrapper's wire with no edit there.
arms :: (Eq a) => (PlayerRelation.PlayerRelation -> a) -> [Arm.Arm a]
arms inject = fmap (\relation -> Arm.nullary (tag relation) (inject relation)) [minBound .. maxBound]

-- | The tag 'codec' writes for this relation, for a wrapper's tagOf.
tag :: PlayerRelation.PlayerRelation -> String
tag = show
