module Parun.Types.HandActionPerformer where

import qualified Parun.Types.Card as Card
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.Game as Game
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 103.5b / CR 103.6: how the closed half performs the effects of an action a
-- card grants from a player's HAND before the game begins -- the card that
-- granted it, the player taking it, and the effects themselves.
--
-- Both windows use it: the mulligan-declaration window (CR 103.5b) and the
-- opening-hand window (CR 103.6), which is explicitly not a mulligan.
--
-- A PARAMETER rather than an import because Parun.Engine.Resolve sits ABOVE
-- Parun.Engine.Mulligan in the module graph, so importing back would close a
-- cycle. That cycle is a fact about the RULES: an opcode restarts a game, a game
-- start draws opening hands, and drawing opening hands performs opcodes.
-- Resolve.resolveSpellWith and Resolve.resolveModesWith take their subgame
-- runner the same way.
--
-- Deliberately has NO default: "no subgame runner" is a real state of the world
-- (Resolve.noSubgame), but "no mulligan performer" is not -- it would silently
-- disable every CR 103.5b card at whichever call site forgot one.
type HandActionPerformer = ObjectId.ObjectId -> PlayerId.PlayerId -> [Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)] -> Game.Game ()
