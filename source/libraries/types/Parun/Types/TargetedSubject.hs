module Parun.Types.TargetedSubject where

import qualified Parun.Types.ActingPermanent as ActingPermanent

-- | CR 115.1 / 601.2c: which targets a becomes-targeted condition watches --
-- permanents, CR 109.5's "you", or both.
data TargetedSubject
  = -- | A permanent the subject admits: ward's bearer, Venerated Rotpriest's
    -- "a creature you control" (CR 702.21a, 601.2c).
    Permanent ActingPermanent.ActingPermanent
  | -- | CR 109.5's "you" alone: Dormant Gomazoa's "whenever you become the
    -- target of a spell".
    You
  | -- | "You or a permanent you control" (Unsettled Mariner, Leyline of
    -- Combustion), CR 601.2c.
    YouOrPermanent ActingPermanent.ActingPermanent
  deriving (Eq, Ord, Show)

-- | The permanent the subject admits, if any.
permanentOf :: TargetedSubject -> Maybe ActingPermanent.ActingPermanent
permanentOf x = case x of
  Permanent p -> Just p
  You -> Nothing
  YouOrPermanent p -> Just p

-- | Whether CR 109.5's "you" counts as a target the subject admits.
includesYou :: TargetedSubject -> Bool
includesYou x = case x of
  Permanent _ -> False
  You -> True
  YouOrPermanent _ -> True
