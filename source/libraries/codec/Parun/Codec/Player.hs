{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Player where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Parun.Codec.CardIdentity as CardIdentity
import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.Designation as Designation
import qualified Parun.Codec.GraveyardOrder as GraveyardOrder
import qualified Parun.Codec.OutsideCard as OutsideCard
import qualified Parun.Codec.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Codec.PlayerDesignation as PlayerDesignation
import qualified Parun.Codec.PrintingId as PrintingId
import qualified Parun.Codec.Status as Status
import qualified Parun.Codec.StickerSheet as StickerSheet
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Designation as Designation.Type
import qualified Parun.Types.GraveyardOrder as GraveyardOrder.Type
import qualified Parun.Types.Player as Player
import qualified Parun.Types.Status as Status.Type

-- | `counters` is 'Common.multiset', whose entries are key/count objects: the
-- field's absent-means-zero convention (Parun.Types.Player) makes a zero entry
-- and an absent one the same to a card, but the map really can hold one once an
-- effect has taken the last counter off, and the round trip has to keep it.
--
-- `commanderCasts` and `commanderDamage` are keyed by a CardIdentity, an
-- object, so both take 'Common.multiset' -- key/count entries. CR 702.124d is
-- why both are keyed per commander rather than per player.
--
-- `speed` is 'Fields.required' over 'Common.maybe' rather than defaulted to 0,
-- because CR 702.179b makes the absence a THIRD state: CR 704.5aa fires on a
-- player with NO speed and would loop forever against one whose speed had been
-- driven to 0 if the two were spelled alike.
codec :: Codec.Codec Player.Player
codec = Fields.object $ do
  life <- Fields.required "life" Common.integer Player.life
  startingLife <- Fields.required "startingLife" Common.integer Player.startingLife
  status <- Fields.defaulted "status" Status.Type.Playing Status.codec Player.status
  counters <- Fields.defaulted "counters" Map.empty (Common.multiset PlayerCounterKind.codec) Player.counters
  ringTemptations <- Fields.defaulted "ringTemptations" 0 Common.natural Player.ringTemptations
  speed <- Fields.required "speed" (Common.maybe Common.natural) Player.speed
  designations <- Fields.defaulted "designations" Set.empty (Common.set PlayerDesignation.codec) Player.designations
  commander <- Fields.defaulted "commander" Set.empty (Common.set CardIdentity.codec) Player.commander
  commanderCasts <- Fields.defaulted "commanderCasts" Map.empty (Common.multiset CardIdentity.codec) Player.commanderCasts
  commanderDamage <- Fields.defaulted "commanderDamage" Map.empty (Common.multiset CardIdentity.codec) Player.commanderDamage
  dungeons <- Fields.defaulted "dungeons" Set.empty (Common.set PrintingId.codec) Player.dungeons
  outsideTheGame <- Fields.defaulted "outsideTheGame" Map.empty (Common.naturalMap PrintingId.codec Common.natural) Player.outsideTheGame
  stickerSheets <- Fields.defaulted "stickerSheets" Seq.empty (Common.seq StickerSheet.codec) Player.stickerSheets
  chosenStickerSheets <- Fields.defaulted "chosenStickerSheets" Set.empty (Common.set Common.natural) Player.chosenStickerSheets
  completedDungeons <- Fields.defaulted "completedDungeons" 0 Common.natural Player.completedDungeons
  completedDungeonNames <- Fields.defaulted "completedDungeonNames" Set.empty (Common.set CardName.codec) Player.completedDungeonNames
  startingDeck <- Fields.defaulted "startingDeck" Map.empty (Common.naturalMap PrintingId.codec Common.natural) Player.startingDeck
  companion <- Fields.defaulted "companion" Nothing (Common.maybe OutsideCard.codec) Player.companion
  companionTaken <- Fields.defaulted "companionTaken" False Common.boolean Player.companionTaken
  graveyardOrder <- Fields.defaulted "graveyardOrder" GraveyardOrder.Type.Indifferent GraveyardOrder.codec Player.graveyardOrder
  crankCounter <- Fields.defaulted "crankCounter" Designation.Type.Sprocket3 Designation.codec Player.crankCounter
  pure
    Player.MkPlayer
      { Player.life = life,
        Player.startingLife = startingLife,
        Player.status = status,
        Player.counters = counters,
        Player.ringTemptations = ringTemptations,
        Player.speed = speed,
        Player.designations = designations,
        Player.commander = commander,
        Player.commanderCasts = commanderCasts,
        Player.commanderDamage = commanderDamage,
        Player.dungeons = dungeons,
        Player.outsideTheGame = outsideTheGame,
        Player.stickerSheets = stickerSheets,
        Player.chosenStickerSheets = chosenStickerSheets,
        Player.completedDungeons = completedDungeons,
        Player.completedDungeonNames = completedDungeonNames,
        Player.startingDeck = startingDeck,
        Player.companion = companion,
        Player.companionTaken = companionTaken,
        Player.graveyardOrder = graveyardOrder,
        Player.crankCounter = crankCounter
      }
