-- | CR 314, scheme cards: which objects are schemes, and which are ongoing.
--
-- A card type and not a format, Parun.Engine.Vanguard's posture: the archenemy
-- is whoever brought a scheme deck (Parun.Engine.Archenemy).
module Parun.Engine.Scheme where

import qualified Data.Set as Set
import qualified Parun.Engine.Game as Game
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Face as Face
import Parun.Types.GameState (GameState)
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.Supertype as Supertype
import qualified Parun.Types.TypeLine as TypeLine

-- | CR 314.1: does this face print the scheme card type?
isSchemeFace :: Face.Face Card.Card -> Bool
isSchemeFace face = Set.member CardType.Scheme (TypeLine.types (Face.typeLine face))

-- | CR 314.2: is this object a scheme card? Read off the printed face, for
-- Parun.Engine.Vanguard.isVanguard's reason: the card never leaves the command
-- zone, where nothing can copy it or change its type.
isScheme :: ObjectId -> GameState -> Bool
isScheme oid gs = maybe False isSchemeFace (Game.faceOf oid gs)

-- | CR 205.4h: is this scheme ongoing?
isOngoing :: ObjectId -> GameState -> Bool
isOngoing oid gs = maybe False (Set.member Supertype.Ongoing . TypeLine.supertypes . Face.typeLine) (Game.faceOf oid gs)
