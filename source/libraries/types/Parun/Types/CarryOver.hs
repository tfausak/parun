module Parun.Types.CarryOver where

-- | CR 400.7a / CR 400.7c: whether the object arriving from this zone change is
-- the permanent a permanent SPELL became, and so keeps the effects that changed
-- the spell's characteristics or controller and the prevention effects that
-- watched it as a source of damage. CR 400.7's default is the opposite -- a
-- moved object is a new object with no memory of the old one -- so this says
-- which of the two a move is.
--
-- A named sum rather than a Bool, for Parun.Types.CoinFace's reason and one more:
-- Parun.Engine.Event.changeZoneAttaching already takes a Bool for CR 406.3's
-- "exiled face down", and two adjacent Bools are two arguments the type checker
-- cannot tell apart at a call site.
--
-- Carried is Parun.Engine.Stack's two permanent-spell branches and nothing else.
-- The other road that survives a zone change does not come through here at all:
-- Alchemy's "perpetually" (Parun.Engine.Event.perpetuate) re-anchors its effects
-- at every move, gated on the effect's own duration rather than on the move.
--
-- CR 400.7b rides Carried where a permission's rider granted the ability, since
-- that grant is stored as the spell is cast (Parun.Engine.Event.permissionRiders),
-- and where another object's static ability granted it, since
-- Parun.Engine.Stack.carryGrants stores that grant just before the move.
--
-- CR 400.7g's carriers are Parun.Engine.Cast.keywordsBefore and
-- Parun.Types.Object.castGrant, and CR 400.7i's for an exile permission's rider
-- is Parun.Engine.Cast.playLand's entry; neither comes through here.
data CarryOver
  = Carried
  | NotCarried
  deriving (Eq, Ord, Show)
