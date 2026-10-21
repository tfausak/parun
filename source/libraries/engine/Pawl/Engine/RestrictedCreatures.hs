-- CR 611.2c: reading a stored, resolution-generated row's subject -- a
-- Pawl.Types.RestrictedCreatures -- against the permanents a rule is asking
-- about. The one reader of that type's two arms, so every stored carrier that
-- holds one (attack and block requirements, attack restrictions, object
-- prohibitions) answers CR 611.2c the same way.
module Pawl.Engine.RestrictedCreatures where

import qualified Data.Set as Set
import qualified Pawl.Engine.Expiry as Expiry
import qualified Pawl.Engine.Filter as Filter
import qualified Pawl.Engine.Projection as Projection
import qualified Pawl.Types.ActiveObjectProhibition as ActiveObjectProhibition
import Pawl.Types.GameState (GameState)
import qualified Pawl.Types.GameState as GameState
import Pawl.Types.ObjectId (ObjectId)
import Pawl.Types.PlayerId (PlayerId)
import qualified Pawl.Types.Prohibition as Prohibition
import qualified Pawl.Types.RestrictedCreatures as RestrictedCreatures

-- Which of `candidates` a stored row's subject covers. A Named row is the id the
-- resolution froze; a Matching row is CR 611.2c's class, re-read against the
-- LIVE board each time it is asked, so a permanent that entered or changed
-- control after the effect began is inside it.
--
-- CR 109.5's "you" in the Filter is the STORED controller, not the source's
-- projected one: the source is a sorcery in a graveyard by now, with no
-- controller to project (Pawl.Types.ActivePlayerEffect's argument).
covered :: PlayerId -> ObjectId -> RestrictedCreatures.RestrictedCreatures ObjectId -> [ObjectId] -> GameState -> [ObjectId]
covered controller source affected candidates gs = case affected of
  RestrictedCreatures.Named oid -> filter (== oid) candidates
  RestrictedCreatures.Matching f ->
    let context = Projection.sourceContext gs (Just controller) source
     in filter (\oid -> Filter.matches context (Projection.viewOfObject oid gs) f) candidates

-- CR 611.2a / 613.11: the `candidates` a stored prohibition of this kind
-- covers right now (GameState.objectProhibitions). A row whose window has not
-- begun covers nothing yet (Expiry.begun): Exhaustion's "during their next
-- untap step" is stored as the sorcery resolves.
prohibited :: Prohibition.Prohibition -> [ObjectId] -> GameState -> Set.Set ObjectId
prohibited what candidates gs =
  let live row = ActiveObjectProhibition.what row == what && Expiry.begun gs (ActiveObjectProhibition.expiry row)
      covers row = covered (ActiveObjectProhibition.controller row) (ActiveObjectProhibition.source row) (ActiveObjectProhibition.affected row) candidates gs
   in Set.fromList (concatMap covers (filter live (GameState.objectProhibitions gs)))
