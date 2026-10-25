module Parun.Codec.QuantitySpec where

import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AgainstExiledPile as AgainstExiledPile
import qualified Parun.Types.AgainstLastCardExiledWith as AgainstLastCardExiledWith
import qualified Parun.Types.AgainstSlot as AgainstSlot
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.Arithmetic as Arithmetic
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CastFrom as CastFrom
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CompletedDungeon as CompletedDungeon
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Count as Count
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.Designation as Designation
import qualified Parun.Types.Devotion as Devotion
import qualified Parun.Types.DistinctOf as DistinctOf
import qualified Parun.Types.Divided as Divided
import qualified Parun.Types.ExiledPile as ExiledPile
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordDesignator as KeywordDesignator
import qualified Parun.Types.KeywordFamily as KeywordFamily
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Types.PlayerCounterTally as PlayerCounterTally
import qualified Parun.Types.PlayerDesignation as PlayerDesignation
import qualified Parun.Types.PlayerDesignationTally as PlayerDesignationTally
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayersDealtDamage as PlayersDealtDamage
import qualified Parun.Types.Plus as Plus
import qualified Parun.Types.ProductionTag as ProductionTag
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Rounding as Rounding
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Times as Times
import qualified Parun.Types.VotesReceived as VotesReceived
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Quantity" $ do
  Spec.it s "Literal" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Literal 5)
      " {\"type\":\"Literal\",\"value\":5} "
  -- CR 202.3 / 208.1: the measure on the wire as Parun.Types.Filter's Measures
  -- writes it.
  Spec.it s "Measure" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Measure Measure.ManaValue)
      " {\"type\":\"Measure\",\"value\":{\"type\":\"ManaValue\"}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Measure Measure.Power)
      " {\"type\":\"Measure\",\"value\":{\"type\":\"Power\"}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Measure Measure.Toughness)
      " {\"type\":\"Measure\",\"value\":{\"type\":\"Toughness\"}} "
  -- Alchemy's intensity, a nullary leaf.
  Spec.it s "Intensity" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.Intensity
      " {\"type\":\"Intensity\"} "
  -- A number an earlier effect of the same resolution bound into a slot. Unlike
  -- X it carries the slot name on the wire, nested under Plus here since
  -- composition is where a recursive decoder loses a payload.
  Spec.it s "InSlot, bare and nested" $ do
    let slot = SlotName.MkSlotName (Text.pack "destroyed")
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.InSlot slot)
      " {\"type\":\"InSlot\",\"value\":\"destroyed\"} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Arithmetic (Arithmetic.Plus (Plus.MkPlus (Quantity.Literal 1) (Quantity.InSlot slot))))
      " {\"type\":\"Plus\",\"value\":{\"left\":{\"type\":\"Literal\",\"value\":1},\"right\":{\"type\":\"InSlot\",\"value\":\"destroyed\"}}} "
  -- CR 601.2d's part of a divided slot, InSlot's wire shape under its own tag.
  Spec.it s "Share" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Share (SlotName.MkSlotName (Text.pack "creatures")))
      " {\"type\":\"Share\",\"value\":\"creatures\"} "
  -- CR 701.4b's yes-or-no over the same slot name, whose wire shape is InSlot's
  -- and whose reading is not: this one asks whether the slot is bound at all.
  Spec.it s "WasBound" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.WasBound (SlotName.MkSlotName (Text.pack "thatBeheldObject")))
      " {\"type\":\"WasBound\",\"value\":\"thatBeheldObject\"} "
  Spec.it s "BoundCount" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.BoundCount (SlotName.MkSlotName (Text.pack "thoseAttackingCreatures")))
      " {\"type\":\"BoundCount\",\"value\":\"thoseAttackingCreatures\"} "
  Spec.it s "UniqueVowelsOnSticker" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.UniqueVowelsOnSticker (SlotName.MkSlotName (Text.pack "placed")))
      " {\"type\":\"UniqueVowelsOnSticker\",\"value\":\"placed\"} "
  Spec.it s "VotesReceived" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.VotesReceived (VotesReceived.MkVotesReceived (SlotName.MkSlotName (Text.pack "votes")) PlayerRef.Candidate))
      " {\"type\":\"VotesReceived\",\"value\":{\"slot\":\"votes\",\"player\":{\"type\":\"Candidate\"}}} "
  Spec.it s "LettersOnNameStickers" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.LettersOnNameStickers (Text.pack "o"))
      " {\"type\":\"LettersOnNameStickers\",\"value\":\"o\"} "
  Spec.it s "NameStickers, a bare tag" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.NameStickers
      " {\"type\":\"NameStickers\"} "
  -- CR 123.8a (Ambassador Blorpityblorpboop).
  Spec.it s "PowerOfStickers, a bare tag" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.PowerOfStickers
      " {\"type\":\"PowerOfStickers\"} "
  Spec.it s "ToughnessOfStickers, a bare tag" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.ToughnessOfStickers
      " {\"type\":\"ToughnessOfStickers\"} "
  Spec.it s "Star" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.Star
      " {\"type\":\"Star\"} "
  Spec.it s "Plus" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Arithmetic (Arithmetic.Plus (Plus.MkPlus (Quantity.Literal 1) Quantity.Star)))
      " {\"type\":\"Plus\",\"value\":{\"left\":{\"type\":\"Literal\",\"value\":1},\"right\":{\"type\":\"Star\"}}} "
  -- Toxic Deluge's -X on the wire: one whole Quantity under the tag, not a pair.
  -- The second case nests a NEGATIVE Literal under it -- the other way this type
  -- says a negative number -- so a decoder that folded the two into one could not
  -- round-trip it.
  Spec.it s "Negate, over a slot read and over a literal" $ do
    let slot = SlotName.MkSlotName (Text.pack "X")
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Arithmetic (Arithmetic.Negate (Quantity.InSlot slot)))
      " {\"type\":\"Negate\",\"value\":{\"type\":\"InSlot\",\"value\":\"X\"}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Arithmetic (Arithmetic.Negate (Quantity.Literal (-2))))
      " {\"type\":\"Negate\",\"value\":{\"type\":\"Literal\",\"value\":-2}} "
  -- Quantity.Count's arm is tagged here and nowhere else: Parun.Codec.Count
  -- writes a bare object, so a Count payload can never be double-tagged.
  Spec.it s "Count is tagged by Quantity, and the payload is Count's bare object" $
    Common.assertCodec
      s
      Quantity.codec
      ( Quantity.Count
          ( Count.MkCount
              (Scope.InZone (InZone.MkInZone Zone.Graveyard (PlayerRef.Relative PlayerRelation.AnyPlayer)))
              (Filter.And [])
              (Aggregation.Distinct DistinctOf.CardTypes)
          )
      )
      " {\"type\":\"Count\",\"value\":{\"scope\":{\"type\":\"InZone\",\"value\":{\"zone\":{\"type\":\"Graveyard\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}}}},\"filter\":{\"type\":\"And\",\"value\":[]},\"aggregation\":{\"type\":\"Distinct\",\"value\":{\"type\":\"CardTypes\"}}}} "
  -- Greatest's payload is a whole Quantity rather than a nullary tag, so a
  -- per-member quantity that is itself a Count has to round-trip.
  Spec.it s "Greatest round-trips a nested Count payload" $
    Common.assertCodec
      s
      Quantity.codec
      ( Quantity.Count
          ( Count.MkCount
              (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer)))
              (Filter.And [])
              ( Aggregation.Greatest
                  ( Quantity.Count
                      ( Count.MkCount
                          (Scope.InZone (InZone.MkInZone Zone.Graveyard (PlayerRef.Relative PlayerRelation.AnyPlayer)))
                          (Filter.And [])
                          (Aggregation.Distinct DistinctOf.CardTypes)
                      )
                  )
              )
          )
      )
      " {\"type\":\"Count\",\"value\":{\"scope\":{\"type\":\"InZone\",\"value\":{\"zone\":{\"type\":\"Battlefield\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}}}},\"filter\":{\"type\":\"And\",\"value\":[]},\"aggregation\":{\"type\":\"Greatest\",\"value\":{\"type\":\"Count\",\"value\":{\"scope\":{\"type\":\"InZone\",\"value\":{\"zone\":{\"type\":\"Graveyard\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}}}},\"filter\":{\"type\":\"And\",\"value\":[]},\"aggregation\":{\"type\":\"Distinct\",\"value\":{\"type\":\"CardTypes\"}}}}}}} "
  -- CR 119.1, with the PlayerRef on the wire saying whose. Serra Avatar's "your"
  -- is the Relative arm; the InSlot arm below is the one a recursive decoder
  -- could lose a payload through, so both are round-tripped.
  Spec.it s "LifeTotal, relative and from a slot" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.LifeTotal (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"LifeTotal\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.LifeTotal (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"LifeTotal\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- CR 103.4, LifeTotal's wire shape: Resolute Archangel's "your".
  Spec.it s "StartingLifeTotal" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.StartingLifeTotal (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"StartingLifeTotal\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
  -- CR 725.1, with a PlayerRef and nothing else on the wire: the arm answers a
  -- 0/1 rather than carrying a number. Dawnglade Regent's "you're the monarch"
  -- is the Relative arm; the InSlot arm beside it is the one a recursive decoder
  -- could lose a payload through, so both are round-tripped, as LifeTotal's are.
  Spec.it s "IsMonarch, relative and from a slot" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.IsMonarch (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"IsMonarch\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.IsMonarch (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"IsMonarch\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- CR 702.131c / 702.195b, IsMonarch's 0/1 answer with the mark beside the
  -- reference. Both marks are round-tripped, since the tag that separates them
  -- rides the payload rather than the arm.
  Spec.it s "HasPlayerDesignation, both marks" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.HasPlayerDesignation (PlayerDesignationTally.MkPlayerDesignationTally (PlayerRef.Relative PlayerRelation.You) PlayerDesignation.CitysBlessing))
      " {\"type\":\"HasPlayerDesignation\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"designation\":{\"type\":\"CitysBlessing\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.HasPlayerDesignation (PlayerDesignationTally.MkPlayerDesignationTally (PlayerRef.Relative PlayerRelation.You) PlayerDesignation.EnduringStory))
      " {\"type\":\"HasPlayerDesignation\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"designation\":{\"type\":\"EnduringStory\"}}} "
  -- CR 103.1, IsMonarch's shape and round-tripped the same two ways: Gemstone
  -- Caverns' gate is the Relative arm, and the InSlot arm beside it is the one a
  -- recursive decoder could lose a payload through.
  Spec.it s "IsStartingPlayer, relative and from a slot" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.IsStartingPlayer (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"IsStartingPlayer\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.IsStartingPlayer (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"IsStartingPlayer\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- CR 102.1, the two arms above's shape and round-tripped the same two ways:
  -- Paladin Class' "during your turn" is the Relative arm, and the InSlot arm
  -- beside it is the one a recursive decoder could lose a payload through.
  Spec.it s "IsActivePlayer, relative and from a slot" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.IsActivePlayer (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"IsActivePlayer\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.IsActivePlayer (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"IsActivePlayer\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- CR 702.112b, CR 701.37b and CR 701.60b: WHICH designation is on the wire and
  -- nothing else, the object it is asked of riding the evaluation rather than a
  -- reference -- so this is Power's shape rather than IsMonarch's.
  Spec.it s "HasDesignation Renowned" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.HasDesignation Designation.Renowned)
      " {\"type\":\"HasDesignation\",\"value\":{\"type\":\"Renowned\"}} "
  Spec.it s "HasDesignation Monstrous" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.HasDesignation Designation.Monstrous)
      " {\"type\":\"HasDesignation\",\"value\":{\"type\":\"Monstrous\"}} "
  Spec.it s "HasDesignation Suspected" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.HasDesignation Designation.Suspected)
      " {\"type\":\"HasDesignation\",\"value\":{\"type\":\"Suspected\"}} "
  -- CR 701.37c: the same designation on the wire, asking the NUMBER rather than
  -- the membership.
  Spec.it s "DesignationValue Monstrous" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.DesignationValue Designation.Monstrous)
      " {\"type\":\"DesignationValue\",\"value\":{\"type\":\"Monstrous\"}} "
  Spec.it s "StoredResultsOfSameValue" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.StoredResultsOfSameValue
      " {\"type\":\"StoredResultsOfSameValue\"} "
  -- CR 716.2b: the object's LEVEL, also with nothing on the wire, and also not a
  -- member of Parun.Types.Designation -- rule 716.2b's designation is a number.
  Spec.it s "ClassLevel" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.ClassLevel
      " {\"type\":\"ClassLevel\"} "
  Spec.it s "WasForetold" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.WasForetold
      " {\"type\":\"WasForetold\"} "
  -- CR 702.104b, with nothing on the wire: the object is whichever one the
  -- quantity is evaluated against.
  Spec.it s "TributeWasPaid" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.TributeWasPaid
      " {\"type\":\"TributeWasPaid\"} "
  -- CR 702.33f, with the DESIGNATOR on the wire: which of the spell's additional
  -- costs is asked about is the whole of what the card names, the object being
  -- whichever one the quantity is evaluated against.
  Spec.it s "TimesPaid" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.TimesPaid (KeywordDesignator.OfKeyword (Keyword.Kicker (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 2])) []))))
      " {\"type\":\"TimesPaid\",\"value\":{\"type\":\"OfKeyword\",\"value\":{\"type\":\"Kicker\",\"value\":{\"mana\":[{\"type\":\"Generic\",\"value\":2}]}}}} "
  -- CR 702.74a / 702.138b / 702.152b, with the keyword designator on the wire:
  -- two families, so a payload codec that ignored its argument cannot
  -- round-trip them, and one whole keyword.
  Spec.it s "CastUsing" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.CastUsing (KeywordDesignator.OfFamily KeywordFamily.Evoke))
      " {\"type\":\"CastUsing\",\"value\":{\"type\":\"OfFamily\",\"value\":{\"type\":\"Evoke\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.CastUsing (KeywordDesignator.OfFamily KeywordFamily.Escape))
      " {\"type\":\"CastUsing\",\"value\":{\"type\":\"OfFamily\",\"value\":{\"type\":\"Escape\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.CastUsing (KeywordDesignator.OfKeyword Keyword.Retrace))
      " {\"type\":\"CastUsing\",\"value\":{\"type\":\"OfKeyword\",\"value\":{\"type\":\"Retrace\"}}} "
  -- CR 107.4h's third sentence, with the tag on the wire and the object still
  -- implicit for WasForetold's reason. BOTH tags, since the wire shape is the whole
  -- of what this arm adds and a payload codec that ignored its argument would
  -- round-trip one of them alone.
  Spec.it s "TagWasSpent" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.TagWasSpent ProductionTag.Snow)
      " {\"type\":\"TagWasSpent\",\"value\":{\"type\":\"Snow\"}} "
  Spec.it s "TagWasSpent Treasure" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.TagWasSpent ProductionTag.Treasure)
      " {\"type\":\"TagWasSpent\",\"value\":{\"type\":\"Treasure\"}} "
  -- CR 107.4h with CR 202.2, the arm above's tag on a different wire word.
  Spec.it s "ChosenColorsItIs" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.ChosenColorsItIs
      " {\"type\":\"ChosenColorsItIs\"} "
  Spec.it s "TagWasSpentOfOwnColor" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.TagWasSpentOfOwnColor ProductionTag.Snow)
      " {\"type\":\"TagWasSpentOfOwnColor\",\"value\":{\"type\":\"Snow\"}} "
  -- CR 202.1a's amount, nothing on the wire for WasForetold's reason.
  Spec.it s "ManaSpent" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.ManaSpent
      " {\"type\":\"ManaSpent\"} "
  -- CR 111.6 and CR 509.1g, with nothing on the wire for WasForetold's reason: the
  -- object is whichever one the quantity is evaluated against.
  Spec.it s "WasToken" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.WasToken
      " {\"type\":\"WasToken\"} "
  Spec.it s "WasAttacking" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.WasAttacking
      " {\"type\":\"WasAttacking\"} "
  Spec.it s "WasBlocking" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.WasBlocking
      " {\"type\":\"WasBlocking\"} "
  -- CR 702.30a's echo window, which carries a PlayerRef where the three above
  -- carry nothing.
  Spec.it s "ControlGainedSinceLastUpkeep" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.ControlGainedSinceLastUpkeep (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"ControlGainedSinceLastUpkeep\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
  -- CR 305.1 / 601.2a's play, the same shape.
  Spec.it s "PlayedBy" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.PlayedBy (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "thatPlayer"))))
      " {\"type\":\"PlayedBy\",\"value\":{\"type\":\"InSlot\",\"value\":\"thatPlayer\"}} "
  -- CR 120.1's damage total, on the wire the same way and for the same reason.
  Spec.it s "DamageDealtToThisTurn" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.DamageDealtToThisTurn
      " {\"type\":\"DamageDealtToThisTurn\"} "
  -- CR 509.1h's status as a look-back, on the wire the same way again.
  Spec.it s "WasBlockedThisTurn" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.WasBlockedThisTurn
      " {\"type\":\"WasBlockedThisTurn\"} "
  -- CR 122.1, with BOTH halves on the wire: a PlayerRef saying whose and a
  -- PlayerCounterKind saying which. Rule 728.1's reading is the Relative one.
  Spec.it s "PlayerCounters, relative and from a slot" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.PlayerCounters (PlayerCounterTally.MkPlayerCounterTally (PlayerRef.Relative PlayerRelation.You) PlayerCounterKind.Rad))
      " {\"type\":\"PlayerCounters\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"kind\":{\"type\":\"Rad\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.PlayerCounters (PlayerCounterTally.MkPlayerCounterTally (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))) PlayerCounterKind.Experience))
      " {\"type\":\"PlayerCounters\",\"value\":{\"player\":{\"type\":\"InSlot\",\"value\":\"target\"},\"kind\":{\"type\":\"Experience\"}}} "
  -- CR 700.5, with both halves on the wire: a PlayerRef saying whose and the set
  -- of colours saying to what. Fanatic of Mogis is the one-colour reading; the
  -- two-colour one beside it is CR 700.5's second sentence, which no card in
  -- data/cards prints yet and which the set is the whole reason for.
  Spec.it s "Devotion, to one colour and to two" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Devotion (Devotion.MkDevotion (PlayerRef.Relative PlayerRelation.You) (Set.singleton Color.Red)))
      " {\"type\":\"Devotion\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"colors\":[{\"type\":\"Red\"}]}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Devotion (Devotion.MkDevotion (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))) (Set.fromList [Color.Black, Color.Green])))
      " {\"type\":\"Devotion\",\"value\":{\"player\":{\"type\":\"InSlot\",\"value\":\"target\"},\"colors\":[{\"type\":\"Black\"},{\"type\":\"Green\"}]}} "
  Spec.it s "PartySize, relative and from a slot" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.PartySize (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"PartySize\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.PartySize (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"PartySize\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- CR 122.1's OBJECT reading, with only a CounterKind on the wire: the object
  -- is whichever one the quantity is evaluated against, so there is no reference
  -- beside the kind. The payload-bearing CounterKind arm (CR 122.1b's keyword
  -- counter) is round-tripped too, since that is the one a recursive decoder
  -- could lose.
  Spec.it s "ObjectCounters, a plain kind and a payload-bearing one" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.ObjectCounters CounterKind.PlusOnePlusOne)
      " {\"type\":\"ObjectCounters\",\"value\":{\"type\":\"PlusOnePlusOne\"}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.ObjectCounters (CounterKind.Keyword Keyword.Flying))
      " {\"type\":\"ObjectCounters\",\"value\":{\"type\":\"Keyword\",\"value\":{\"type\":\"Flying\"}}} "
  -- The same tally with no kind named at all (CR 122.1): a bare tag, since the sum
  -- is over every kind and the object is still whichever one the quantity is
  -- evaluated against. Round-tripped separately from the arm above because
  -- Parun.JsonCodec.Arm's tag function forces a constructor's TAG and not its arm,
  -- so a missing arm is a decode failure rather than a compile error.
  Spec.it s "ObjectCountersOfAnyKind, a bare tag" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.ObjectCountersOfAnyKind
      " {\"type\":\"ObjectCountersOfAnyKind\"} "
  -- CR 508.3b, with a PlayerRef and nothing else on the wire: what is counted is
  -- the combat record. Rule 702.121a's melee is the Relative arm; the InSlot arm
  -- beside it is the one a recursive decoder could lose a payload through, as
  -- LifeTotal's and IsMonarch's are.
  Spec.it s "OpponentsAttacked, relative and from a slot" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.OpponentsAttacked (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"OpponentsAttacked\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.OpponentsAttacked (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"OpponentsAttacked\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- CR 508.1a, on OpponentsAttacked's terms: a PlayerRef and nothing else, with
  -- the same recursive-decoder pair. Mardu Skullhunter's is the Relative arm.
  Spec.it s "AttackersDeclaredThisTurn, relative and from a slot" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.AttackersDeclaredThisTurn (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"AttackersDeclaredThisTurn\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.AttackersDeclaredThisTurn (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"AttackersDeclaredThisTurn\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- Giant Turtle's and Avenge's last-turn reads, each a PlayerRef alone.
  Spec.it s "AttackedInLastTurnOf and AttackersInTheirLastTurn" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.AttackedInLastTurnOf (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"AttackedInLastTurnOf\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.AttackersInTheirLastTurn (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"AttackersInTheirLastTurn\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
  -- CR 701.9a, with a PlayerRef and nothing else on the wire: what is counted is
  -- the turn-scoped event log. Asmoranomardicadaistinaculdacar's is the Relative
  -- arm; the InSlot arm beside it is the one a recursive decoder could lose a
  -- payload through, as OpponentsAttacked's is.
  Spec.it s "CardsDiscardedThisTurn, relative and from a slot" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.CardsDiscardedThisTurn (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"CardsDiscardedThisTurn\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.CardsDiscardedThisTurn (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"CardsDiscardedThisTurn\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  Spec.it s "CardsDrawnThisTurn" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.CardsDrawnThisTurn (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"CardsDrawnThisTurn\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
  -- CR 603.1b, on CardsDiscardedThisTurn's terms. Avatar Aang's is the Relative
  -- arm.
  Spec.it s "BendingsThisTurn" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.BendingsThisTurn (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"BendingsThisTurn\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
  -- CR 119.3, on CardsDiscardedThisTurn's terms: a PlayerRef and nothing else,
  -- with the same recursive-decoder pair. Fortifying Draught's is the Relative
  -- arm.
  Spec.it s "LifeGainedThisTurn, relative and from a slot" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.LifeGainedThisTurn (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"LifeGainedThisTurn\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.LifeGainedThisTurn (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"LifeGainedThisTurn\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- CR 120.1: a PlayerRef and an optional kind. Furious Spinesplitter's is the
  -- Relative arm over Opponent with no kind; Tymna the Weaver's narrows it to CR
  -- 510.2's combat damage.
  Spec.it s "PlayersDealtDamageThisTurn, any damage and combat damage" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.PlayersDealtDamageThisTurn PlayersDealtDamage.MkPlayersDealtDamage {PlayersDealtDamage.player = PlayerRef.Relative PlayerRelation.Opponent, PlayersDealtDamage.kind = Nothing})
      " {\"type\":\"PlayersDealtDamageThisTurn\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"Opponent\"}}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.PlayersDealtDamageThisTurn PlayersDealtDamage.MkPlayersDealtDamage {PlayersDealtDamage.player = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target")), PlayersDealtDamage.kind = Just DamageKind.Combat})
      " {\"type\":\"PlayersDealtDamageThisTurn\",\"value\":{\"player\":{\"type\":\"InSlot\",\"value\":\"target\"},\"kind\":{\"type\":\"Combat\"}}} "
  -- CR 120.1 again, the same log read as a TOTAL: Petrified Wood-Kin's rule
  -- 702.54b X is the Relative arm over Opponent, and it must not share a tag with
  -- the tally above, which answers a different number on the same board.
  Spec.it s "DamageDealtToPlayersThisTurn, relative and from a slot" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.DamageDealtToPlayersThisTurn (PlayerRef.Relative PlayerRelation.Opponent))
      " {\"type\":\"DamageDealtToPlayersThisTurn\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"Opponent\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.DamageDealtToPlayersThisTurn (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"DamageDealtToPlayersThisTurn\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- CR 601.2i, on CardsDiscardedThisTurn's terms again: a PlayerRef and nothing
  -- else. Daybreak Ranger // Nightfall Predator writes the Candidate arm, which is
  -- how a per-player quantity is read under a count over players; the InSlot arm
  -- beside it is the recursive-decoder pair the two cases above make.
  Spec.it s "SpellsCastLastTurn, from the fold's candidate and from a slot" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.SpellsCastLastTurn PlayerRef.Candidate)
      " {\"type\":\"SpellsCastLastTurn\",\"value\":{\"type\":\"Candidate\"}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.SpellsCastLastTurn (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"SpellsCastLastTurn\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- Ertai's Scorn's per-opponent tally, SpellsCastLastTurn's wire one turn over.
  Spec.it s "SpellsCastThisTurn carries its PlayerRef" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.SpellsCastThisTurn PlayerRef.Candidate)
      " {\"type\":\"SpellsCastThisTurn\",\"value\":{\"type\":\"Candidate\"}} "
  -- CR 608.2n with nothing on the wire either: the ability is the one the
  -- quantity is evaluated against, reached through AgainstSlot over CR 602.2a's
  -- "thisAbility", and "this turn" is the event log's own extent.
  Spec.it s "TimesResolvedThisTurn is nullary" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.TimesResolvedThisTurn
      " {\"type\":\"TimesResolvedThisTurn\"} "
  -- CR 702.40a with nothing on the wire: the spell is the one the quantity is
  -- evaluated against, and "this turn" is the event log's own extent.
  Spec.it s "SpellsCastBefore is nullary" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.SpellsCastBefore
      " {\"type\":\"SpellsCastBefore\"} "
  -- CR 702.69a with nothing on the wire either: the count reads the whole of the
  -- event log's extent and names no object at all.
  Spec.it s "PermanentsDiedThisTurn is nullary" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.PermanentsDiedThisTurn
      " {\"type\":\"PermanentsDiedThisTurn\"} "
  -- CR 508.1a: the combat's record, naming no player.
  Spec.it s "AttackersDeclaredThisCombat is nullary" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.AttackersDeclaredThisCombat
      " {\"type\":\"AttackersDeclaredThisCombat\"} "
  -- CR 702.185c: the family is the payload, as CastUsing's is.
  Spec.it s "SpellsCastUsingThisTurn" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.SpellsCastUsingThisTurn KeywordFamily.Warp)
      " {\"type\":\"SpellsCastUsingThisTurn\",\"value\":{\"type\":\"Warp\"}} "
  -- CR 100.6a with nothing on the wire: the tally is the match's, so it names
  -- neither a player nor an object.
  Spec.it s "SubgamesThisMatch is nullary" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.SubgamesThisMatch
      " {\"type\":\"SubgamesThisMatch\"} "
  -- CR 309.7, on CardsDiscardedThisTurn's terms again: a PlayerRef and nothing
  -- else. Gloom Stalker writes the Relative You arm, which is the only spelling
  -- any printing uses -- "as long as YOU'VE completed a dungeon"; the InSlot arm
  -- beside it is the recursive-decoder pair the cases above make.
  Spec.it s "DungeonsCompleted, relative and from a slot" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.DungeonsCompleted (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"DungeonsCompleted\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.DungeonsCompleted (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"DungeonsCompleted\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- CR 903.8's tally, a PlayerRef and nothing else (Henzie "Toolbox" Torre).
  Spec.it s "CommanderCasts" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.CommanderCasts (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"CommanderCasts\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
  -- CR 309.7 asked of one dungeon by name, the tally's named sibling.
  Spec.it s "CompletedDungeon, a player and a printed name" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.CompletedDungeon (CompletedDungeon.MkCompletedDungeon (PlayerRef.Relative PlayerRelation.You) (CardName.MkCardName (Text.pack "Tomb of Annihilation"))))
      " {\"type\":\"CompletedDungeon\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"dungeon\":\"Tomb of Annihilation\"}} "
  -- CR 400.7 with NOTHING on the wire either: the object is the one the quantity
  -- is evaluated against, and "this turn" is the event log's own extent.
  Spec.it s "EnteredThisTurn is nullary" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.EnteredThisTurn
      " {\"type\":\"EnteredThisTurn\"} "
  -- CR 400.7's origin zone carries an InZone -- the payload a Count's scope
  -- carries, so the decoder that rejects a shared zone scoped to one player
  -- covers this arm without a second predicate.
  Spec.it s "EnteredFrom carries an InZone" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.EnteredFrom (InZone.MkInZone Zone.Graveyard (PlayerRef.Relative PlayerRelation.You)))
      " {\"type\":\"EnteredFrom\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"zone\":{\"type\":\"Graveyard\"}}} "
  -- CR 601.2a's cast wraps that same InZone beside a caster of its own; the
  -- payload's own arms are Parun.Codec.CastFromSpec's, and what this proves is
  -- the TAG that reaches them.
  Spec.it s "WasCastFrom carries a CastFrom, caster elided at You" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.WasCastFrom (CastFrom.MkCastFrom (PlayerRef.Relative PlayerRelation.You) (InZone.MkInZone Zone.Graveyard (PlayerRef.Relative PlayerRelation.You))))
      " {\"type\":\"WasCastFrom\",\"value\":{\"from\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"zone\":{\"type\":\"Graveyard\"}}}} "
  -- CR 509.1h with only the skip on the wire: the object is the one the
  -- quantity is evaluated against.
  Spec.it s "BlockersBeyond carries how many blockers it skips" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.BlockersBeyond 1)
      " {\"type\":\"BlockersBeyond\",\"value\":1} "
  -- CR 702.184c, Power's wire shape: nothing beside the tag, the object being
  -- the one the quantity is evaluated against.
  Spec.it s "StationMeasure is nullary" $
    Common.assertCodec
      s
      Quantity.codec
      Quantity.StationMeasure
      " {\"type\":\"StationMeasure\"} "
  -- A slot and a payload on the wire. Nested once, since a recursive decoder is
  -- where a payload gets lost -- and the inner arm is one whose OWN answer the
  -- slot moves, which is the whole point of the constructor.
  Spec.it s "AgainstSlot, bare and nested" $ do
    let slot = SlotName.MkSlotName (Text.pack "creature")
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.AgainstSlot (AgainstSlot.MkAgainstSlot slot (Quantity.Measure Measure.Power)))
      " {\"type\":\"AgainstSlot\",\"value\":{\"slot\":\"creature\",\"quantity\":{\"type\":\"Measure\",\"value\":{\"type\":\"Power\"}}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Arithmetic (Arithmetic.Plus (Plus.MkPlus (Quantity.Literal 1) (Quantity.AgainstSlot (AgainstSlot.MkAgainstSlot slot (Quantity.ObjectCounters CounterKind.PlusOnePlusOne))))))
      " {\"type\":\"Plus\",\"value\":{\"left\":{\"type\":\"Literal\",\"value\":1},\"right\":{\"type\":\"AgainstSlot\",\"value\":{\"slot\":\"creature\",\"quantity\":{\"type\":\"ObjectCounters\",\"value\":{\"type\":\"PlusOnePlusOne\"}}}}}} "
  -- A pile, then what to read off each card in it. Nested once for
  -- AgainstSlot's reason -- a recursive decoder is where a payload gets lost --
  -- and over another pile and the toughness half of CR 607.2a's read, so the
  -- two assertions cannot agree by accident.
  Spec.it s "AgainstExiledPile, bare and nested" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.AgainstExiledPile (AgainstExiledPile.MkAgainstExiledPile ExiledPile.OwnAbilities (Quantity.Measure Measure.Power)))
      " {\"type\":\"AgainstExiledPile\",\"value\":{\"pile\":{\"type\":\"OwnAbilities\"},\"quantity\":{\"type\":\"Measure\",\"value\":{\"type\":\"Power\"}}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Arithmetic (Arithmetic.Plus (Plus.MkPlus (Quantity.Literal 1) (Quantity.AgainstExiledPile (AgainstExiledPile.MkAgainstExiledPile ExiledPile.CraftMaterials (Quantity.Measure Measure.Toughness))))))
      " {\"type\":\"Plus\",\"value\":{\"left\":{\"type\":\"Literal\",\"value\":1},\"right\":{\"type\":\"AgainstExiledPile\",\"value\":{\"pile\":{\"type\":\"CraftMaterials\"},\"quantity\":{\"type\":\"Measure\",\"value\":{\"type\":\"Toughness\"}}}}}} "
  -- CR 607.2a / 613.7d (Duplicant): the filter picking the card, then what to
  -- read off it.
  Spec.it s "AgainstLastCardExiledWith" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.AgainstLastCardExiledWith (AgainstLastCardExiledWith.MkAgainstLastCardExiledWith (Filter.HasCardType CardType.Creature) (Quantity.Measure Measure.Toughness)))
      " {\"type\":\"AgainstLastCardExiledWith\",\"value\":{\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"quantity\":{\"type\":\"Measure\",\"value\":{\"type\":\"Toughness\"}}}} "
  -- CR 107.1a's direction and the value it applies to, in that order. Nested
  -- once for AgainstSlot's reason -- a recursive decoder is where a payload gets
  -- lost -- and over a Count, which is the shape both producers print.
  Spec.it s "Divided, both directions" $ do
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Arithmetic (Arithmetic.Divided (Divided.MkDivided Rounding.Down (Quantity.Literal 5) (Quantity.Literal 2))))
      " {\"type\":\"Divided\",\"value\":{\"rounding\":{\"type\":\"Down\"},\"quantity\":{\"type\":\"Literal\",\"value\":5},\"divisor\":{\"type\":\"Literal\",\"value\":2}}} "
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Arithmetic (Arithmetic.Divided (Divided.MkDivided Rounding.Up (Quantity.LifeTotal PlayerRef.Candidate) (Quantity.Literal 2))))
      " {\"type\":\"Divided\",\"value\":{\"rounding\":{\"type\":\"Up\"},\"quantity\":{\"type\":\"LifeTotal\",\"value\":{\"type\":\"Candidate\"}},\"divisor\":{\"type\":\"Literal\",\"value\":2}}} "
  -- CR 107.1's factor and the value it multiplies, over the Count that Blessed
  -- Reversal prints -- Divided's reason for nesting, one arm over.
  Spec.it s "Times, over a count" $
    Common.assertCodec
      s
      Quantity.codec
      (Quantity.Arithmetic (Arithmetic.Times (Times.MkTimes 3 (Quantity.LifeTotal PlayerRef.Candidate))))
      " {\"type\":\"Times\",\"value\":{\"factor\":3,\"quantity\":{\"type\":\"LifeTotal\",\"value\":{\"type\":\"Candidate\"}}}} "
  -- Forcing the schema is what proves the RECURSIVE definition terminates, and
  -- it proves more of that now than it used to: Negate names `codec` itself
  -- while Plus, Divided, Times, AgainstSlot and Count each hand it to a payload
  -- codec in another module, so the loop runs through five siblings. assertHasSchema
  -- renders the whole tree rather than just its outer tag, so a definition that
  -- failed to emit a $ref on re-entry would hang here rather than pass.
  Spec.it s "has a schema" $ Common.assertHasSchema s Quantity.codec
