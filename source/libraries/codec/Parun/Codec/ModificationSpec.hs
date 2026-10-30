module Parun.Codec.ModificationSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.Modification as Modification
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.ActivationRestriction as ActivationRestriction
import qualified Parun.Types.Activator as Activator
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CastingPermission as CastingPermission
import qualified Parun.Types.ChangeMode as ChangeMode
import qualified Parun.Types.ChangeWord as ChangeWord
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CombatDamageOption as CombatDamageOption
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.CostKeyword as CostKeyword
import qualified Parun.Types.ExiledCardAbilities as ExiledCardAbilities
import qualified Parun.Types.ExiledPile as ExiledPile
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.FullText as FullText
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordFamily as KeywordFamily
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.ModeMemory as ModeMemory
import qualified Parun.Types.ModeSelection as ModeSelection
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ModifyPowerToughness as ModifyPowerToughness
import qualified Parun.Types.NameInsertion as NameInsertion
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Pool as Pool
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SetBasePowerToughness as SetBasePowerToughness
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.SubtypeFamily as SubtypeFamily
import qualified Parun.Types.Supertype as Supertype
import qualified Parun.Types.TargetSlot as TargetSlot
import qualified Parun.Types.TextWord as TextWord

-- | The `ability` parameter is instantiated at @GrantedAbility Text@, which is
-- what every card position holds with `card` in turn instantiated at 'Text.Text'
-- -- the posture 'Parun.Codec.ActivatedAbilitySpec' takes for the same reason.
codec :: Codec.Codec (Modification.Modification (GrantedAbility.GrantedAbility Text.Text))
codec = Modification.codec (GrantedAbility.codec Common.text)

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Modification" $ do
  -- layer 6 (Serpent's Gift).
  Spec.it s "GainKeyword" $
    Common.assertCodec
      s
      codec
      (Modification.GainKeyword Keyword.Deathtouch)
      " {\"type\":\"GainKeyword\",\"value\":{\"type\":\"Deathtouch\"}} "
  -- layer 6, CR 202.1a: only the keyword is on the wire, since the cost this
  -- grant states is the RECEIVING card's mana cost and no card writes it.
  Spec.it s "GainKeywordAtManaCost" $
    Common.assertCodec
      s
      codec
      (Modification.GainKeywordAtManaCost CostKeyword.Scavenge)
      " {\"type\":\"GainKeywordAtManaCost\",\"value\":{\"type\":\"Scavenge\"}} "
  -- layer 6, CR 702.5a: the granted enchant ability. The payload is a
  -- whole TargetSlot, so this arm's wire form is the one Face.enchant's entries
  -- already take.
  Spec.it s "GainEnchant" $
    Common.assertCodec
      s
      codec
      (Modification.GainEnchant (TargetSlot.required Pool.Creatures Nothing))
      " {\"type\":\"GainEnchant\",\"value\":{\"pool\":{\"type\":\"Creatures\"}}} "
  -- layer 6, CR 702.5a: the removal of one enchant instance (Animate Dead).
  Spec.it s "LoseEnchant" $
    Common.assertCodec
      s
      codec
      (Modification.LoseEnchant (TargetSlot.required Pool.Creatures Nothing))
      " {\"type\":\"LoseEnchant\",\"value\":{\"pool\":{\"type\":\"Creatures\"}}} "
  -- layer 6, CR 601.3: a granted casting permission.
  Spec.it s "GainCastingPermission" $
    Common.assertCodec
      s
      codec
      (Modification.GainCastingPermission CastingPermission.CastFromLibraryWhileSearching)
      " {\"type\":\"GainCastingPermission\",\"value\":{\"type\":\"CastFromLibraryWhileSearching\"}} "
  -- layer 6 (Humility).
  Spec.it s "LoseAllAbilities" $
    Common.assertCodec
      s
      codec
      Modification.LoseAllAbilities
      " {\"type\":\"LoseAllAbilities\"} "
  -- layer 6, CR 123.7a (Pin Collection).
  Spec.it s "GainAbilitiesOfStickers" $
    Common.assertCodec
      s
      codec
      Modification.GainAbilitiesOfStickers
      " {\"type\":\"GainAbilitiesOfStickers\"} "
  -- layer 6, CR 613.1f: the removal that names ONE ability (Gliding Licid).
  Spec.it s "LoseNamedAbility carries the name" $
    Common.assertCodec
      s
      codec
      (Modification.LoseNamedAbility (AbilityName.MkAbilityName (Text.pack "animate")))
      " {\"type\":\"LoseNamedAbility\",\"value\":\"animate\"} "
  -- layer 6, CR 613.1f: the removal that names ONE rule-702 keyword (Sky
  -- Tether). The payload is a whole Keyword, so a written instance round-trips
  -- with its payload -- Scarwood Hag's "loses forestwalk" is what needs that.
  Spec.it s "LoseKeyword carries the keyword" $
    Common.assertCodec
      s
      codec
      (Modification.LoseKeyword Keyword.Flying)
      " {\"type\":\"LoseKeyword\",\"value\":{\"type\":\"Flying\"}} "
  -- layer 6, CR 613.1f / 702.14a: the removal that names a FAMILY (Hammerheim).
  -- The payload is a nullary tag rather than the tagged pair above, since
  -- Parun.Types.KeywordFamily is payload-free -- "all landwalk abilities" names
  -- no land type.
  Spec.it s "LoseKeywordFamily carries the family" $
    Common.assertCodec
      s
      codec
      (Modification.LoseKeywordFamily KeywordFamily.Landwalk)
      " {\"type\":\"LoseKeywordFamily\",\"value\":{\"type\":\"Landwalk\"}} "
  -- layer 7b (Humility 1/1; Opalescence mana value).
  Spec.it s "SetBasePowerToughness" $
    Common.assertCodec
      s
      codec
      (Modification.SetBasePowerToughness (SetBasePowerToughness.MkSetBasePowerToughness (Just (Quantity.Literal 1)) (Just (Quantity.Literal 1))))
      " {\"type\":\"SetBasePowerToughness\",\"value\":{\"power\":{\"type\":\"Literal\",\"value\":1},\"toughness\":{\"type\":\"Literal\",\"value\":1}}} "
  -- layer 7c (Giant Growth +3/+3).
  Spec.it s "ModifyPowerToughness" $
    Common.assertCodec
      s
      codec
      (Modification.ModifyPowerToughness (ModifyPowerToughness.MkModifyPowerToughness (Quantity.Literal 3) (Quantity.Literal 3)))
      " {\"type\":\"ModifyPowerToughness\",\"value\":{\"power\":{\"type\":\"Literal\",\"value\":3},\"toughness\":{\"type\":\"Literal\",\"value\":3}}} "
  -- layer 4, CR 305.7 set (Blood Moon -> Mountain).
  Spec.it s "LandSubtype Replace" $
    Common.assertCodec
      s
      codec
      (Modification.LandSubtype ChangeMode.Replace Subtype.Mountain)
      " {\"type\":\"LandSubtype\",\"value\":{\"mode\":{\"type\":\"Replace\"},\"subtype\":{\"type\":\"Mountain\"}}} "
  -- The mode and family only: the subtype is read from the effect's source at
  -- projection time, so it is not on the wire.
  Spec.it s "ChosenSubtype" $
    Common.assertCodec
      s
      codec
      (Modification.ChosenSubtype ChangeMode.InAddition SubtypeFamily.CreatureType)
      " {\"type\":\"ChosenSubtype\",\"value\":{\"family\":{\"type\":\"CreatureType\"},\"mode\":{\"type\":\"InAddition\"}}} "
  -- layer 4, CR 305.7 add (Urborg -> Swamp).
  Spec.it s "LandSubtype InAddition" $
    Common.assertCodec
      s
      codec
      (Modification.LandSubtype ChangeMode.InAddition Subtype.Swamp)
      " {\"type\":\"LandSubtype\",\"value\":{\"mode\":{\"type\":\"InAddition\"},\"subtype\":{\"type\":\"Swamp\"}}} "
  -- layer 4, CR 205.1a set (Turn to Frog -> Frog).
  Spec.it s "CreatureSubtype Replace" $
    Common.assertCodec
      s
      codec
      (Modification.CreatureSubtype ChangeMode.Replace Subtype.Frog)
      " {\"type\":\"CreatureSubtype\",\"value\":{\"mode\":{\"type\":\"Replace\"},\"subtype\":{\"type\":\"Frog\"}}} "
  -- layer 4, CR 205.1b add (Life and Limb -> Saproling).
  Spec.it s "CreatureSubtype InAddition" $
    Common.assertCodec
      s
      codec
      (Modification.CreatureSubtype ChangeMode.InAddition Subtype.Saproling)
      " {\"type\":\"CreatureSubtype\",\"value\":{\"mode\":{\"type\":\"InAddition\"},\"subtype\":{\"type\":\"Saproling\"}}} "
  -- layer 4, CR 205.1b add over the whole of CR 205.3m (Wings of Velis Vel).
  Spec.it s "AddEveryCreatureSubtype" $
    Common.assertCodec
      s
      codec
      Modification.AddEveryCreatureSubtype
      " {\"type\":\"AddEveryCreatureSubtype\"} "
  -- layer 4, CR 205.1a removal over the whole of CR 205.3m (Nameless Inversion).
  Spec.it s "LoseEveryCreatureSubtype" $
    Common.assertCodec
      s
      codec
      Modification.LoseEveryCreatureSubtype
      " {\"type\":\"LoseEveryCreatureSubtype\"} "
  -- layer 4, CR 205.1a set to a linked card's creature types (Duplicant).
  Spec.it s "SetCreatureSubtypesOfLastCardExiledWith carries its filter" $
    Common.assertCodec
      s
      codec
      (Modification.SetCreatureSubtypesOfLastCardExiledWith (Filter.HasCardType CardType.Creature))
      " {\"type\":\"SetCreatureSubtypesOfLastCardExiledWith\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- layer 4, CR 205.1b add outside the land and creature families (Ygra, Eater
  -- of All). A different subtype from every arm above, so a codec that crossed
  -- this arm with one of them cannot pass both.
  Spec.it s "AddSubtype" $
    Common.assertCodec
      s
      codec
      (Modification.AddSubtype Subtype.Food)
      " {\"type\":\"AddSubtype\",\"value\":{\"type\":\"Food\"}} "
  -- layer 4, CR 205.1a removal (Haunted Plate Mail). A different subtype from
  -- the add above, so a codec that crossed the two cannot pass both.
  Spec.it s "RemoveSubtype" $
    Common.assertCodec
      s
      codec
      (Modification.RemoveSubtype Subtype.Equipment)
      " {\"type\":\"RemoveSubtype\",\"value\":{\"type\":\"Equipment\"}} "
  -- layer 4, CR 205.1a set (Song of the Dryads -> land). A different card type
  -- from the add below, so a codec that crossed the two modes cannot pass both.
  Spec.it s "CardType Replace" $
    Common.assertCodec
      s
      codec
      (Modification.CardType ChangeMode.Replace CardType.Land)
      " {\"type\":\"CardType\",\"value\":{\"mode\":{\"type\":\"Replace\"},\"cardType\":{\"type\":\"Land\"}}} "
  -- layer 4, CR 205.1b add (Opalescence -> Creature).
  Spec.it s "CardType InAddition" $
    Common.assertCodec
      s
      codec
      (Modification.CardType ChangeMode.InAddition CardType.Creature)
      " {\"type\":\"CardType\",\"value\":{\"mode\":{\"type\":\"InAddition\"},\"cardType\":{\"type\":\"Creature\"}}} "
  -- layer 4, CR 205.1a removal (CR 702.151b -> not a creature).
  Spec.it s "LoseCardType" $
    Common.assertCodec
      s
      codec
      (Modification.LoseCardType CardType.Creature)
      " {\"type\":\"LoseCardType\",\"value\":{\"type\":\"Creature\"}} "
  -- layer 4, CR 205.4b grant (Leyline of Singularity -> legendary).
  Spec.it s "AddSupertype" $
    Common.assertCodec
      s
      codec
      (Modification.AddSupertype Supertype.Legendary)
      " {\"type\":\"AddSupertype\",\"value\":{\"type\":\"Legendary\"}} "
  -- layer 4, CR 205.4b removal (Arcum's Weathervane -> no longer snow).
  Spec.it s "RemoveSupertype" $
    Common.assertCodec
      s
      codec
      (Modification.RemoveSupertype Supertype.Snow)
      " {\"type\":\"RemoveSupertype\",\"value\":{\"type\":\"Snow\"}} "
  -- layer 3, CR 612 (Magical Hack: from -> to).
  Spec.it s "ChangeWord" $
    Common.assertCodec
      s
      codec
      (Modification.ChangeWord (ChangeWord.MkChangeWord (TextWord.SubtypeWord Subtype.Mountain) (TextWord.SubtypeWord Subtype.Island)))
      " {\"type\":\"ChangeWord\",\"value\":{\"from\":{\"type\":\"Mountain\"},\"to\":{\"type\":\"Island\"}}} "
  -- layer 2, CR 613.1b: the PlayerId is BAKED at effect creation, unlike
  -- SetControllerToSource below.
  Spec.it s "SetController carries its baked PlayerId" $
    Common.assertCodec
      s
      codec
      (Modification.SetController (PlayerId.MkPlayerId 0))
      " {\"type\":\"SetController\",\"value\":0} "
  -- layer 2, CR 613.1b: the only shape a printed static ability can grant
  -- control with, since the controller is DERIVED at projection time rather
  -- than baked. Must not decode as SetController.
  Spec.it s "SetControllerToSource" $
    Common.assertCodec
      s
      codec
      Modification.SetControllerToSource
      " {\"type\":\"SetControllerToSource\"} "
  -- layer 5, CR 613.1e / 105.3: a SET, not an add.
  Spec.it s "Colors Replace carries its colour set" $
    Common.assertCodec
      s
      codec
      (Modification.Colors ChangeMode.Replace (Set.singleton Color.Blue))
      " {\"type\":\"Colors\",\"value\":{\"mode\":{\"type\":\"Replace\"},\"colors\":[{\"type\":\"Blue\"}]}} "
  -- layer 5, CR 613.1e / 105.3: an ADD, not a set.
  Spec.it s "Colors InAddition" $
    Common.assertCodec
      s
      codec
      (Modification.Colors ChangeMode.InAddition (Set.singleton Color.Blue))
      " {\"type\":\"Colors\",\"value\":{\"mode\":{\"type\":\"InAddition\"},\"colors\":[{\"type\":\"Blue\"}]}} "
  -- layer 5, CR 613.1e / 105.3: the colour is read at projection time off the
  -- effect's source, so the arm carries only whether it replaces or adds.
  Spec.it s "ChosenColor" $
    Common.assertCodec
      s
      codec
      (Modification.ChosenColor ChangeMode.Replace)
      " {\"type\":\"ChosenColor\",\"value\":{\"type\":\"Replace\"}} "
  -- layer 6, CR 702.165a: the abilities come off the effect's SOURCE, so the arm
  -- carries only the keywords printed above the backup line.
  Spec.it s "GainAbilitiesOfSource" $
    Common.assertCodec
      s
      codec
      (Modification.GainAbilitiesOfSource (Set.singleton Keyword.Flash))
      " {\"type\":\"GainAbilitiesOfSource\",\"value\":[{\"type\":\"Flash\"}]} "
  -- layer 6, CR 607.2a: the abilities come off the linked cards, so the arm
  -- carries only which pile and the rider's restrictions.
  Spec.it s "GainExiledCardAbilities" $
    Common.assertCodec
      s
      codec
      (Modification.GainExiledCardAbilities ExiledCardAbilities.MkExiledCardAbilities {ExiledCardAbilities.cards = Filter.IsExiledWithSource ExiledPile.CraftMaterials, ExiledCardAbilities.restrictions = [ActivationRestriction.TimesEachTurn 1]})
      " {\"type\":\"GainExiledCardAbilities\",\"value\":{\"cards\":{\"type\":\"IsExiledWithSource\",\"value\":{\"type\":\"CraftMaterials\"}},\"restrictions\":[{\"type\":\"TimesEachTurn\",\"value\":1}]}} "
  -- layer 3, CR 612.5: the two sides come from the effect's affected set, so
  -- the arm itself is payload-free.
  Spec.it s "ExchangeTextBoxes" $
    Common.assertCodec
      s
      codec
      Modification.ExchangeTextBoxes
      " {\"type\":\"ExchangeTextBoxes\"} "
  -- layer 3, CR 612.7: Spy Kit's "all names of nonlegendary creature cards".
  Spec.it s "AddNamesMatching carries its filter" $
    Common.assertCodec
      s
      codec
      (Modification.AddNamesMatching (Filter.And [Filter.HasCardType CardType.Creature, Filter.Not (Filter.HasSupertype Supertype.Legendary)]))
      " {\"type\":\"AddNamesMatching\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"Not\",\"value\":{\"type\":\"HasSupertype\",\"value\":{\"type\":\"Legendary\"}}}]}} "
  -- layer 3, CR 612.6: Volrath's Shapeshifter's "full text of that card",
  -- here with no text of its own beside it.
  Spec.it s "SetName carries the name" $
    Common.assertCodec
      s
      codec
      (Modification.SetName (CardName.MkCardName (Text.pack "Legitimate Businessperson")))
      " {\"type\":\"SetName\",\"value\":\"Legitimate Businessperson\"} "
  Spec.it s "InsertNameWords carries the word and its position" $
    Common.assertCodec
      s
      codec
      (Modification.InsertNameWords (NameInsertion.MkNameInsertion (Text.pack "Hot Dog") 2))
      " {\"type\":\"InsertNameWords\",\"value\":{\"word\":\"Hot Dog\",\"after\":2}} "
  Spec.it s "HasFullText carries its graveyard and extra text" $
    Common.assertCodec
      s
      codec
      (Modification.HasFullText (FullText.MkFullText (PlayerRef.Relative PlayerRelation.You) []))
      " {\"type\":\"HasFullText\",\"value\":{\"graveyard\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"alsoHas\":[]}} "
  -- layer 7d, CR 613.4d: switches power and toughness. Payload-free.
  Spec.it s "SwitchPowerToughness" $
    Common.assertCodec
      s
      codec
      Modification.SwitchPowerToughness
      " {\"type\":\"SwitchPowerToughness\"} "
  Spec.it s "AssignCombatDamageWithToughness" $
    Common.assertCodec
      s
      codec
      Modification.AssignCombatDamageWithToughness
      " {\"type\":\"AssignCombatDamageWithToughness\"} "
  Spec.it s "MayAssignCombatDamage" $
    Common.assertCodec
      s
      codec
      (Modification.MayAssignCombatDamage CombatDamageOption.AsThoughUnblocked)
      " {\"type\":\"MayAssignCombatDamage\",\"value\":{\"type\":\"AsThoughUnblocked\"}} "
  -- layer 6, CR 702.184c: this object's controller's station abilities read
  -- toughness instead of power. Payload-free, self-only.
  Spec.it s "GrantsStationToughness" $
    Common.assertCodec
      s
      codec
      Modification.GrantsStationToughness
      " {\"type\":\"GrantsStationToughness\"} "
  -- Alchemy's "intensifies by 1" (Static Discharge).
  Spec.it s "Intensify" $
    Common.assertCodec
      s
      codec
      (Modification.Intensify (Quantity.Literal 1))
      " {\"type\":\"Intensify\",\"value\":{\"type\":\"Literal\",\"value\":1}} "
  -- layer 6, CR 613.1f: a whole quoted activated ability, Presence of Gond's
  -- "{T}: Create a 1/1 green Elf Warrior creature token" reduced to its cost.
  Spec.it s "GainAbility" $
    Common.assertCodec
      s
      codec
      ( Modification.GainAbility
          ( GrantedAbility.Activated
              ( ActivatedAbility.MkActivatedAbility
                  (Cost.MkCost Nothing [CostComponent.TapThis])
                  []
                  0
                  Nothing
                  (Modal.MkModal (Seq.singleton (Mode.MkMode Seq.empty Map.empty)) (ModeSelection.ChooseExactly 1) ModeMemory.NoMemory)
                  []
                  Activator.Controller
                  Nothing
                  Nothing
                  Nothing
              )
          )
      )
      " {\"type\":\"GainAbility\",\"value\":{\"type\":\"Activated\",\"value\":{\"cost\":{\"mana\":null,\"components\":[{\"type\":\"TapThis\"}]},\"modal\":{\"modes\":[{}]}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
