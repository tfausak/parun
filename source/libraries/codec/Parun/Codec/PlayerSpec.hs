module Parun.Codec.PlayerSpec where

import qualified Data.Map as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.Player as Player
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardIdentity as CardIdentity
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.Departure as Departure
import qualified Parun.Types.Designation as Designation
import qualified Parun.Types.GraveyardOrder as GraveyardOrder
import qualified Parun.Types.OutsideCard as OutsideCard
import qualified Parun.Types.Player as Player
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Types.PlayerDesignation as PlayerDesignation
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PrintingId as PrintingId
import qualified Parun.Types.Status as Status

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Player" $ do
  -- CR 103.4's starting life total and nothing else: a player outside a
  -- Commander game (CR 903.3), with no speed at all (CR 702.179b) and no
  -- counters. `speed` is null here and a number below, which CR 702.179b and CR
  -- 704.5aa make two different players -- no speed at all, against a speed that
  -- has a value. `startingLife` is required beside `life`, since no default
  -- answers for every variant (CR 119.1a-e). Every other field is
  -- 'Fields.defaulted' and sits at its
  -- default, so this literal is where the OMISSION is pinned: a field switched
  -- back to 'Fields.required' reappears in it.
  Spec.it s "a player at the start of an ordinary game" $
    Common.assertCodec
      s
      Player.codec
      Player.MkPlayer
        { Player.life = 20,
          Player.startingLife = 20,
          Player.status = Status.Playing,
          Player.counters = Map.empty,
          Player.ringTemptations = 0,
          Player.speed = Nothing,
          Player.designations = Set.empty,
          Player.commander = Set.empty,
          Player.commanderCasts = Map.empty,
          Player.commanderDamage = Map.empty,
          Player.dungeons = Set.empty,
          Player.outsideTheGame = Map.empty,
          Player.stickerSheets = Seq.empty,
          Player.chosenStickerSheets = Set.empty,
          Player.completedDungeons = 0,
          Player.completedDungeonNames = Set.empty,
          Player.startingDeck = Map.empty,
          Player.companion = Nothing,
          Player.companionTaken = False,
          Player.graveyardOrder = GraveyardOrder.Indifferent,
          Player.crankCounter = Designation.Sprocket3
        }
      " {\"life\":20,\"startingLife\":20,\"speed\":null} "
  -- Every axis away from the case above. `life` is NEGATIVE, which CR 104.3b
  -- reaches through a state-based action rather than clamping at zero, so the
  -- field is an Integer and a Natural encoder would reject this state.
  -- `counters` carries a kind at ZERO beside one at two: an absent kind reads as
  -- zero (Parun.Types.Player), so the two are the same to a card, but the map
  -- really holds the entry and the round trip has to keep it.
  -- TWO commanders, which is CR 702.124a's partner deck: `commander` is a set and
  -- `commanderCasts` a map keyed per commander, so the round trip has to keep both apart.
  Spec.it s "a departed Commander player with counters, speed and dungeon" $
    Common.assertCodec
      s
      Player.codec
      Player.MkPlayer
        { Player.life = -1,
          Player.startingLife = 40,
          Player.status = Status.Departed Departure.Conceded,
          Player.counters =
            Map.fromList
              [ (PlayerCounterKind.Energy, 2),
                (PlayerCounterKind.Poison, 0)
              ],
          Player.ringTemptations = 3,
          Player.speed = Just 4,
          Player.designations = Set.fromList [PlayerDesignation.CitysBlessing, PlayerDesignation.EnduringStory],
          Player.commander = Set.fromList [CardIdentity.MkCardIdentity 20 (PlayerId.MkPlayerId 1), CardIdentity.MkCardIdentity 21 (PlayerId.MkPlayerId 1)],
          Player.commanderCasts = Map.fromList [(CardIdentity.MkCardIdentity 20 (PlayerId.MkPlayerId 1), 6), (CardIdentity.MkCardIdentity 21 (PlayerId.MkPlayerId 1), 19)],
          Player.commanderDamage = Map.singleton (CardIdentity.MkCardIdentity 22 (PlayerId.MkPlayerId 2)) 8,
          Player.dungeons = Set.fromList [PrintingId.MkPrintingId 9, PrintingId.MkPrintingId 11],
          Player.outsideTheGame = Map.singleton (PrintingId.MkPrintingId 12) 13,
          Player.stickerSheets = Seq.empty,
          Player.chosenStickerSheets = Set.fromList [0, 2],
          Player.completedDungeons = 10,
          Player.completedDungeonNames = Set.fromList [CardName.MkCardName (Text.pack "Tomb of Annihilation"), CardName.MkCardName (Text.pack "Undercity")],
          Player.startingDeck = Map.singleton (PrintingId.MkPrintingId 14) 15,
          Player.companion = Just (OutsideCard.InPool (PrintingId.MkPrintingId 16)),
          Player.companionTaken = True,
          Player.graveyardOrder = GraveyardOrder.Matters,
          Player.crankCounter = Designation.Sprocket1
        }
      ( " {\"life\":-1,\"startingLife\":40,\"status\":{\"type\":\"Departed\",\"value\":{\"type\":\"Conceded\"}}"
          <> ",\"counters\":[{\"key\":{\"type\":\"Energy\"},\"value\":2}"
          <> ",{\"key\":{\"type\":\"Poison\"},\"value\":0}]"
          <> ",\"ringTemptations\":3,\"speed\":4"
          <> ",\"designations\":[{\"type\":\"CitysBlessing\"},{\"type\":\"EnduringStory\"}]"
          <> ",\"commander\":[{\"serial\":20,\"startingOwner\":1},{\"serial\":21,\"startingOwner\":1}],\"commanderCasts\":[{\"key\":{\"serial\":20,\"startingOwner\":1},\"value\":6},{\"key\":{\"serial\":21,\"startingOwner\":1},\"value\":19}]"
          <> ",\"commanderDamage\":[{\"key\":{\"serial\":22,\"startingOwner\":2},\"value\":8}],\"dungeons\":[9,11],\"outsideTheGame\":{\"12\":13},\"chosenStickerSheets\":[0,2],\"completedDungeons\":10,\"completedDungeonNames\":[\"Tomb of Annihilation\",\"Undercity\"]"
          <> ",\"startingDeck\":{\"14\":15},\"companion\":{\"type\":\"InPool\",\"value\":16},\"companionTaken\":true"
          <> ",\"graveyardOrder\":{\"type\":\"Matters\"},\"crankCounter\":{\"type\":\"Sprocket1\"}} "
      )
  Spec.it s "has a schema" $
    Common.assertHasSchema s Player.codec
