module Parun.Codec.PlayerEffectSpec where

import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.PlayerEffect as PlayerEffect
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Audience as Audience
import qualified Parun.Types.CantSearchLibraries as CantSearchLibraries
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CastFromZone as CastFromZone
import qualified Parun.Types.CoinFace as CoinFace
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CombatDeclaration as CombatDeclaration
import qualified Parun.Types.CostChange as CostChange
import qualified Parun.Types.CostModifier as CostModifier
import qualified Parun.Types.CostSubject as CostSubject
import qualified Parun.Types.CounterProhibition as CounterProhibition
import qualified Parun.Types.DamagePattern as DamagePattern
import qualified Parun.Types.DrawReveal as DrawReveal
import qualified Parun.Types.EntriesTrigger as EntriesTrigger
import qualified Parun.Types.EntryTriggering as EntryTriggering
import qualified Parun.Types.ExtraVotes as ExtraVotes
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.GameOutcome as GameOutcome
import qualified Parun.Types.HexproofExemption as HexproofExemption
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordDesignator as KeywordDesignator
import qualified Parun.Types.KeywordFamily as KeywordFamily
import qualified Parun.Types.LandAllowance as LandAllowance
import qualified Parun.Types.LoyaltyClause as LoyaltyClause
import qualified Parun.Types.LoyaltyGrant as LoyaltyGrant
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaFilter as ManaFilter
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.ModifiedRoll as ModifiedRoll
import qualified Parun.Types.PermissionLimit as PermissionLimit
import qualified Parun.Types.PermissionPool as PermissionPool
import qualified Parun.Types.PermissionVerb as PermissionVerb
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Types.PlayerEffect as PlayerEffect
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.PlotFromZone as PlotFromZone
import qualified Parun.Types.RevealObligation as RevealObligation
import qualified Parun.Types.RollModifier as RollModifier
import qualified Parun.Types.ShownCards as ShownCards
import qualified Parun.Types.Shows as Shows
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SpendManaAsThough as SpendManaAsThough
import qualified Parun.Types.StackObjectKind as StackObjectKind
import qualified Parun.Types.StatedFlip as StatedFlip
import qualified Parun.Types.TapForMana as TapForMana
import qualified Parun.Types.TargetRestriction as TargetRestriction
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerEffect" $ do
  -- CR 601.3 / Silence.
  Spec.it s "CantCastSpells" $
    Common.assertCodec
      s
      PlayerEffect.codec
      PlayerEffect.CantCastSpells
      " {\"type\":\"CantCastSpells\"} "
  -- CR 601.3 / Rule of Law.
  Spec.it s "CantCastMoreThan" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantCastMoreThan 1)
      " {\"type\":\"CantCastMoreThan\",\"value\":1} "
  -- CR 613.11 / 601.2f / Thalia: the tag Parun.Codec.CostModifier's payload rides.
  Spec.it s "ModifyCost" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.ModifyCost (CostModifier.MkCostModifier CostSubject.Spells (Filter.Not (Filter.HasCardType CardType.Creature)) Nothing Nothing Nothing Nothing (CostChange.Increase (ManaCost.MkManaCost [ManaSymbol.Generic 1]))))
      " {\"type\":\"ModifyCost\",\"value\":{\"subject\":{\"type\":\"Spells\"},\"matching\":{\"type\":\"Not\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"change\":{\"type\":\"Increase\",\"value\":[{\"type\":\"Generic\",\"value\":1}]}}} "
  -- CR 305.2 / Exploration.
  Spec.it s "PlayAdditionalLands, Exploration's one" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.PlayAdditionalLands (LandAllowance.Additional 1))
      " {\"type\":\"PlayAdditionalLands\",\"value\":{\"type\":\"Additional\",\"value\":1}} "
  -- CR 305.2 / Azusa, Lost but Seeking: the OTHER amount, so a codec that
  -- dropped the payload would round-trip one of these and not both.
  Spec.it s "PlayAdditionalLands, Azusa's two" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.PlayAdditionalLands (LandAllowance.Additional 2))
      " {\"type\":\"PlayAdditionalLands\",\"value\":{\"type\":\"Additional\",\"value\":2}} "
  -- CR 305.2 / Naya.
  Spec.it s "PlayAdditionalLands, Naya's any number" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.PlayAdditionalLands LandAllowance.AnyNumber)
      " {\"type\":\"PlayAdditionalLands\",\"value\":{\"type\":\"AnyNumber\"}} "
  -- CR 402.2 / Reliquary Tower.
  Spec.it s "NoMaximumHandSize" $
    Common.assertCodec
      s
      PlayerEffect.codec
      PlayerEffect.NoMaximumHandSize
      " {\"type\":\"NoMaximumHandSize\"} "
  -- CR 402.2 / The Ten Rings. This is the shape data/cards/the-ten-rings.json
  -- carries.
  Spec.it s "SetMaximumHandSize, The Ten Rings' ten" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.SetMaximumHandSize 10)
      " {\"type\":\"SetMaximumHandSize\",\"value\":10} "
  -- CR 402.2 / Cursed Rack: the OTHER number, so a codec that dropped the payload
  -- would round-trip one of these and not both.
  Spec.it s "SetMaximumHandSize, Cursed Rack's four" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.SetMaximumHandSize 4)
      " {\"type\":\"SetMaximumHandSize\",\"value\":4} "
  -- CR 402.2 / 613.11 / Minamo Scrollkeeper. This is the shape
  -- data/cards/minamo-scrollkeeper.json carries.
  Spec.it s "IncreaseMaximumHandSize, Minamo Scrollkeeper's one" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.IncreaseMaximumHandSize 1)
      " {\"type\":\"IncreaseMaximumHandSize\",\"value\":1} "
  -- CR 402.2 / 613.11 / Gnat Miser. This is the shape
  -- data/cards/gnat-miser.json carries -- a DIFFERENT tag from the increase
  -- above, not the same tag with a sign, and the two cases together are what a
  -- codec collapsing the pair would fail.
  Spec.it s "ReduceMaximumHandSize, Gnat Miser's one" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.ReduceMaximumHandSize 1)
      " {\"type\":\"ReduceMaximumHandSize\",\"value\":1} "
  -- CR 402.2: the OTHER number on the reducing arm, so a codec that dropped the
  -- payload would round-trip one of these and not both. Thought Nibbler prints
  -- this two; no file in data/cards/ carries it.
  Spec.it s "ReduceMaximumHandSize, a second number" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.ReduceMaximumHandSize 2)
      " {\"type\":\"ReduceMaximumHandSize\",\"value\":2} "
  -- CR 500.5 / 703.4q / Upwelling: no mana type named.
  Spec.it s "DontLoseUnspentMana, Upwelling's whole pool" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.DontLoseUnspentMana ManaFilter.Any)
      " {\"type\":\"DontLoseUnspentMana\",\"value\":{\"type\":\"Any\"}} "
  -- CR 106.1a: the OTHER filter, so a codec that dropped the payload would
  -- round-trip one of these and not both.
  Spec.it s "DontLoseUnspentMana, Omnath's green only" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.DontLoseUnspentMana (ManaFilter.OfType (ManaType.Colored Color.Green)))
      " {\"type\":\"DontLoseUnspentMana\",\"value\":{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"Green\"}}}} "
  -- CR 500.5 / 119.3 / Yurlok of Scorch Thrash: nullary, the sentence naming no
  -- mana to narrow by.
  Spec.it s "LoseLifeForUnspentMana, Yurlok's mana burn" $
    Common.assertCodec
      s
      PlayerEffect.codec
      PlayerEffect.LoseLifeForUnspentMana
      " {\"type\":\"LoseLifeForUnspentMana\"} "
  -- CR 609.4b / Celestial Dawn's mana sentence, whose two clauses are one
  -- PlayerEffect entry each -- a codec that dropped the payload's `only` would
  -- round-trip one of them and not both.
  Spec.it s "SpendManaAsThough, Celestial Dawn's permission" $
    Common.assertCodec
      s
      PlayerEffect.codec
      ( PlayerEffect.SpendManaAsThough
          SpendManaAsThough.MkSpendManaAsThough
            { SpendManaAsThough.which = ManaFilter.OfType (ManaType.Colored Color.White),
              SpendManaAsThough.asThough = Set.singleton (ManaType.Colored Color.Blue),
              SpendManaAsThough.only = False
            }
      )
      " {\"type\":\"SpendManaAsThough\",\"value\":{\"which\":{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"White\"}}},\"asThough\":[{\"type\":\"Colored\",\"value\":{\"type\":\"Blue\"}}],\"only\":false}} "
  Spec.it s "SpendManaAsThough, Celestial Dawn's restriction" $
    Common.assertCodec
      s
      PlayerEffect.codec
      ( PlayerEffect.SpendManaAsThough
          SpendManaAsThough.MkSpendManaAsThough
            { SpendManaAsThough.which = ManaFilter.NotOfType (ManaType.Colored Color.White),
              SpendManaAsThough.asThough = Set.singleton ManaType.Colorless,
              SpendManaAsThough.only = True
            }
      )
      " {\"type\":\"SpendManaAsThough\",\"value\":{\"which\":{\"type\":\"NotOfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"White\"}}},\"asThough\":[{\"type\":\"Colorless\"}],\"only\":true}} "
  -- CR 702.18a / Ivory Mask: shroud names no player, so the scope is everybody.
  Spec.it s "CantBeTargetedBy, shroud's EachPlayer" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantBeTargetedBy (PlayerScope.Related PlayerRelation.AnyPlayer))
      " {\"type\":\"CantBeTargetedBy\",\"value\":{\"type\":\"AnyPlayer\"}} "
  -- CR 702.11c: the OTHER scope, so a codec that dropped the payload would
  -- round-trip one of these and not both.
  Spec.it s "CantBeTargetedBy, hexproof's Opponents" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantBeTargetedBy (PlayerScope.Related PlayerRelation.Opponent))
      " {\"type\":\"CantBeTargetedBy\",\"value\":{\"type\":\"Opponent\"}} "
  -- CR 601.3b / Vedalken Orrery: "spells" names no quality, so the filter is the
  -- trivial predicate. This is the shape data/cards/vedalken-orrery.json carries.
  Spec.it s "CastAsThoughItHadFlash, Vedalken Orrery's unqualified spells" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CastAsThoughItHadFlash (Filter.And []))
      " {\"type\":\"CastAsThoughItHadFlash\",\"value\":{\"type\":\"And\",\"value\":[]}} "
  -- CR 601.1a / Scout's Warning: the PLAY-scoped sibling, carrying its Filter.
  Spec.it s "MayPlayAsThoughItHadFlash, Scout's Warning's creature card" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.MayPlayAsThoughItHadFlash (Filter.HasCardType CardType.Creature))
      " {\"type\":\"MayPlayAsThoughItHadFlash\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- CR 602.5d / Leonin Shikari: "equip abilities", the family with its cost dropped.
  Spec.it s "ActivateKeywordAtInstantSpeed, Leonin Shikari's equip abilities" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.ActivateKeywordAtInstantSpeed (KeywordDesignator.OfFamily KeywordFamily.Equip))
      " {\"type\":\"ActivateKeywordAtInstantSpeed\",\"value\":{\"type\":\"OfFamily\",\"value\":{\"type\":\"Equip\"}}} "
  -- CR 606.3 / The Wandering Emperor: "her loyalty abilities", the source itself.
  Spec.it s "LoyaltyGrant, The Wandering Emperor's own" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.LoyaltyGrant (LoyaltyGrant.MkLoyaltyGrant LoyaltyClause.Window Filter.IsSource))
      " {\"type\":\"LoyaltyGrant\",\"value\":{\"relaxes\":{\"type\":\"Window\"},\"permanents\":{\"type\":\"IsSource\"}}} "
  -- CR 602.2 / Piracy: "you may tap lands you don't control for mana".
  Spec.it s "MayTapForMana, Piracy's" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.MayTapForMana (TapForMana.MkTapForMana (Filter.HasCardType CardType.Land) Nothing))
      " {\"type\":\"MayTapForMana\",\"value\":{\"permanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}}} "
  -- CR 601.3b's "certain qualities" (Yeva, Nature's Herald), so a codec that
  -- dropped the payload would round-trip one of these and not both.
  Spec.it s "CastAsThoughItHadFlash, a filter that names qualities" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CastAsThoughItHadFlash (Filter.And [Filter.HasColor Color.Green, Filter.HasCardType CardType.Creature]))
      " {\"type\":\"CastAsThoughItHadFlash\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"HasColor\",\"value\":{\"type\":\"Green\"}},{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}]}} "
  -- CR 701.6a, twice for CastAsThoughItHadFlash's reason: Spider-Punk narrows by
  -- nothing and Prowling Serpopard narrows by a card type, so a codec that
  -- dropped the payload would round-trip one of these and not both. WHOSE spells
  -- is the CARRIER's scope (Parun.Codec.PlayerStaticAbility) and never rides here.
  Spec.it s "CantBeCountered, an empty filter" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantBeCountered (CounterProhibition.MkCounterProhibition (Filter.And []) (Filter.And [])))
      " {\"type\":\"CantBeCountered\",\"value\":{\"countered\":{\"type\":\"And\",\"value\":[]}}} "
  Spec.it s "CantBeCountered, a filter that names qualities" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantBeCountered (CounterProhibition.MkCounterProhibition (Filter.HasCardType CardType.Creature) (Filter.And [])))
      " {\"type\":\"CantBeCountered\",\"value\":{\"countered\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  -- Autumn's Veil's "by blue or black spells": the counterers' key.
  Spec.it s "CantBeCountered, counterers that name qualities" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantBeCountered (CounterProhibition.MkCounterProhibition (Filter.Not Filter.IsAbility) (Filter.HasColor Color.Blue)))
      " {\"type\":\"CantBeCountered\",\"value\":{\"countered\":{\"type\":\"Not\",\"value\":{\"type\":\"IsAbility\"}},\"counterers\":{\"type\":\"HasColor\",\"value\":{\"type\":\"Blue\"}}}} "
  -- CR 115 / 101.2 / Autumn's Veil: a targeting restriction whose affected set
  -- is a Filter.
  Spec.it s "RestrictTargeting" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.RestrictTargeting (TargetRestriction.MkTargetRestriction (Filter.HasCardType CardType.Creature) StackObjectKind.Spell (Filter.HasColor Color.Black)))
      " {\"type\":\"RestrictTargeting\",\"value\":{\"affected\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"aimers\":{\"type\":\"HasColor\",\"value\":{\"type\":\"Black\"}},\"kind\":{\"type\":\"Spell\"}}} "
  -- CR 702.11e / Detection Tower: the tag around the payload
  -- Parun.Codec.HexproofExemptionSpec covers.
  Spec.it s "TargetPastHexproof" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.TargetPastHexproof (HexproofExemption.MkHexproofExemption (Filter.HasCardType CardType.Creature) True))
      " {\"type\":\"TargetPastHexproof\",\"value\":{\"permanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"players\":true}} "
  -- CR 615.12 / Spider-Punk, whose sentence names no quality of the damage: the
  -- pattern that admits everything, whose every field is its default, so the
  -- payload is an empty object rather than absent. WHOSE damage is the carrier's
  -- scope (Parun.Codec.PlayerStaticAbility) rather than anything riding here.
  Spec.it s "DamageCantBePrevented, naming no quality of the damage" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.DamageCantBePrevented (DamagePattern.MkDamagePattern Nothing (Filter.And []) Nothing Nothing Nothing Nothing Nothing))
      " {\"type\":\"DamageCantBePrevented\",\"value\":{}} "
  -- CR 615.12 narrowed / Excruciator, "damage that would be dealt by this
  -- creature": the same effect keyed to its own source (CR 614.15's relation),
  -- which is what makes the payload worth carrying.
  Spec.it s "DamageCantBePrevented, naming its own source" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.DamageCantBePrevented (DamagePattern.MkDamagePattern Nothing Filter.IsSource Nothing Nothing Nothing Nothing Nothing))
      " {\"type\":\"DamageCantBePrevented\",\"value\":{\"whatSource\":{\"type\":\"IsSource\"}}} "
  -- CR 614.9 / Lava Burst, "if Lava Burst would deal damage to a creature, that
  -- damage can't be ... dealt instead to another permanent or player": the
  -- redirection twin, narrowed on both of the pattern's printed halves at once.
  Spec.it s "DamageCantBeRedirected, naming its own source and a recipient" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.DamageCantBeRedirected (DamagePattern.MkDamagePattern Nothing Filter.IsSource (Just (Filter.HasCardType CardType.Creature)) Nothing Nothing Nothing Nothing))
      " {\"type\":\"DamageCantBeRedirected\",\"value\":{\"whatRecipient\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"whatSource\":{\"type\":\"IsSource\"}}} "
  -- CR 701.23 / Leonin Arbiter.
  Spec.it s "CantSearchLibraries" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantSearchLibraries CantSearchLibraries.MkCantSearchLibraries {CantSearchLibraries.library = PlayerScope.Related PlayerRelation.AnyPlayer, CantSearchLibraries.cause = PlayerScope.Related PlayerRelation.AnyPlayer})
      " {\"type\":\"CantSearchLibraries\",\"value\":{\"library\":{\"type\":\"AnyPlayer\"},\"cause\":{\"type\":\"AnyPlayer\"}}} "
  -- CR 702.16j / The Stasis Coffin: "protection from everything" as the empty
  -- conjunction.
  Spec.it s "HasProtectionFrom" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.HasProtectionFrom (Filter.And []))
      " {\"type\":\"HasProtectionFrom\",\"value\":{\"type\":\"And\",\"value\":[]}} "
  -- CR 725 / Jared Carthalion, True Heir.
  Spec.it s "CantBecomeMonarch" $
    Common.assertCodec
      s
      PlayerEffect.codec
      PlayerEffect.CantBecomeMonarch
      " {\"type\":\"CantBecomeMonarch\"} "
  -- CR 701.32 / All in Good Time.
  Spec.it s "CantSetSchemesInMotion" $
    Common.assertCodec
      s
      PlayerEffect.codec
      PlayerEffect.CantSetSchemesInMotion
      " {\"type\":\"CantSetSchemesInMotion\"} "
  -- CR 603.2d / Yarok, the Desecrated.
  Spec.it s "EntriesTrigger" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.EntriesTrigger EntriesTrigger.MkEntriesTrigger {EntriesTrigger.entrants = Filter.And [], EntriesTrigger.triggering = EntryTriggering.AnAdditionalTime})
      " {\"type\":\"EntriesTrigger\",\"value\":{\"entrants\":{\"type\":\"And\",\"value\":[]},\"triggering\":{\"type\":\"AnAdditionalTime\"}}} "
  -- CR 723.2 / Opposition Agent.
  Spec.it s "ControlledWhileSearching" $
    Common.assertCodec
      s
      PlayerEffect.codec
      PlayerEffect.ControlledWhileSearching
      " {\"type\":\"ControlledWhileSearching\"} "
  -- CR 509.1a / Odric, Master Tactician.
  Spec.it s "YouChoose" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.YouChoose CombatDeclaration.Blockers)
      " {\"type\":\"YouChoose\",\"value\":{\"type\":\"Blockers\"}} "
  -- CR 701.23 / Opposition Agent.
  Spec.it s "ExilesFoundWhileSearching" $
    Common.assertCodec
      s
      PlayerEffect.codec
      PlayerEffect.ExilesFoundWhileSearching
      " {\"type\":\"ExilesFoundWhileSearching\"} "
  -- CR 508.1c / Angelic Arbiter.
  Spec.it s "CantAttackWithCreatures" $
    Common.assertCodec
      s
      PlayerEffect.codec
      PlayerEffect.CantAttackWithCreatures
      " {\"type\":\"CantAttackWithCreatures\"} "
  -- CR 601.3a / Damping Engine's cast half.
  Spec.it s "CantCastMatching" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantCastMatching (Filter.Or [Filter.HasCardType CardType.Artifact, Filter.HasCardType CardType.Creature]))
      " {\"type\":\"CantCastMatching\",\"value\":{\"type\":\"Or\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Artifact\"}},{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}]}} "
  -- CR 307.5 / Teferi, Mage of Zhalfir's third clause, nullary.
  Spec.it s "CastOnlyAtSorcerySpeed" $
    Common.assertCodec
      s
      PlayerEffect.codec
      PlayerEffect.CastOnlyAtSorcerySpeed
      " {\"type\":\"CastOnlyAtSorcerySpeed\"} "
  -- CR 602.5 / Sen Triplets' second clause, which names every ability.
  Spec.it s "CantActivateAbilities" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantActivateAbilities Nothing (Filter.And []))
      " {\"type\":\"CantActivateAbilities\",\"value\":{}} "
  -- CR 702.193a / Kang the Conqueror's "power-up abilities can't be activated".
  Spec.it s "CantActivateAbilities naming a keyword" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantActivateAbilities (Just (KeywordDesignator.OfKeyword Keyword.PowerUp)) (Filter.And []))
      " {\"type\":\"CantActivateAbilities\",\"value\":{\"designator\":{\"type\":\"OfKeyword\",\"value\":{\"type\":\"PowerUp\"}}}} "
  -- CR 602.5 / Grand Abolisher's "abilities of artifacts, creatures, or
  -- enchantments", which names the sources.
  Spec.it s "CantActivateAbilities naming the sources" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantActivateAbilities Nothing (Filter.HasCardType CardType.Artifact))
      " {\"type\":\"CantActivateAbilities\",\"value\":{\"sources\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Artifact\"}}}} "
  -- CR 305.1 / City in a Bottle's land half, whose Filter names the land
  -- (Damping Engine's writes the empty And instead).
  Spec.it s "CantPlayLands" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantPlayLands (Filter.HasName (CardName.MkCardName (Text.pack "Bazaar of Baghdad"))))
      " {\"type\":\"CantPlayLands\",\"value\":{\"type\":\"HasName\",\"value\":\"Bazaar of Baghdad\"}} "
  -- CR 601.3 / Yawgmoth's Will, whose sentence names no quality of the spell and
  -- whose zone is the caster's own.
  Spec.it s "CastFrom, an empty filter" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CastFrom (CastFromZone.MkCastFromZone (InZone.MkInZone Zone.Graveyard (PlayerRef.Relative PlayerRelation.You)) (Filter.And []) PermissionLimit.Unlimited PermissionVerb.Cast PermissionPool.EveryCard [] 0))
      " {\"type\":\"CastFrom\",\"value\":{\"from\":{\"zone\":{\"type\":\"Graveyard\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"matching\":{\"type\":\"And\",\"value\":[]}}} "
  -- CR 601.3 / Garruk's Horde's "creature spells", the arm that used to be a
  -- CastFromTopOfLibrary of its own: the zone is all that told the two apart.
  Spec.it s "CastFrom, a filter that names qualities" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CastFrom (CastFromZone.MkCastFromZone (InZone.MkInZone Zone.Library (PlayerRef.Relative PlayerRelation.You)) (Filter.HasCardType CardType.Creature) PermissionLimit.Unlimited PermissionVerb.Cast PermissionPool.EveryCard [] 0))
      " {\"type\":\"CastFrom\",\"value\":{\"from\":{\"zone\":{\"type\":\"Library\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"matching\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  -- CR 601.3 / Sen Triplets: the zone belongs to the player a slot names, which
  -- is the whole of what the reference buys.
  Spec.it s "CastFrom, a slot naming whose zone" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CastFrom (CastFromZone.MkCastFromZone (InZone.MkInZone Zone.Hand (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "opponent")))) (Filter.And []) PermissionLimit.Unlimited PermissionVerb.Cast PermissionPool.EveryCard [] 0))
      " {\"type\":\"CastFrom\",\"value\":{\"from\":{\"zone\":{\"type\":\"Hand\"},\"player\":{\"type\":\"InSlot\",\"value\":\"opponent\"}},\"matching\":{\"type\":\"And\",\"value\":[]}}} "
  -- CR 305.1 / Crucible of Worlds, whose sentence narrows no land.
  Spec.it s "PlayLandsFrom" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.PlayLandsFrom (InZone.MkInZone Zone.Graveyard (PlayerRef.Relative PlayerRelation.You)))
      " {\"type\":\"PlayLandsFrom\",\"value\":{\"zone\":{\"type\":\"Graveyard\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}}} "
  -- CR 702.170f / Fblthp, Lost on the Range.
  Spec.it s "PlotFrom" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.PlotFrom (PlotFromZone.MkPlotFromZone (InZone.MkInZone Zone.Library (PlayerRef.Relative PlayerRelation.You)) (Filter.Not (Filter.HasCardType CardType.Land))))
      " {\"type\":\"PlotFrom\",\"value\":{\"from\":{\"zone\":{\"type\":\"Library\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"matching\":{\"type\":\"Not\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}}}} "
  -- CR 118.9 / Omniscience, whose sentence names no quality of the spell.
  Spec.it s "CastFromHandWithoutPayingManaCost, an empty filter" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CastFromHandWithoutPayingManaCost (Filter.And []))
      " {\"type\":\"CastFromHandWithoutPayingManaCost\",\"value\":{\"type\":\"And\",\"value\":[]}} "
  -- The same grant narrowed, which is the axis a second printing would use.
  Spec.it s "CastFromHandWithoutPayingManaCost, a filter that names qualities" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CastFromHandWithoutPayingManaCost (Filter.HasCardType CardType.Creature))
      " {\"type\":\"CastFromHandWithoutPayingManaCost\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- Solemnity's first sentence, which names no kind, so the key is null -- the
  -- wire form data/cards/solemnity.json writes.
  Spec.it s "CantGetCounters, no kind named" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantGetCounters Nothing)
      " {\"type\":\"CantGetCounters\",\"value\":null} "
  -- Melira, Sylvok Outcast's first sentence, which names one.
  Spec.it s "CantGetCounters, a named kind" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.CantGetCounters (Just PlayerCounterKind.Poison))
      " {\"type\":\"CantGetCounters\",\"value\":{\"type\":\"Poison\"}} "
  -- CR 705.3 as Edgar, King of Figaro prints it, and the wire form
  -- data/cards/edgar-king-of-figaro.json writes.
  Spec.it s "StateCoinFlip, both halves of CR 705.3" $
    Common.assertCodec
      s
      PlayerEffect.codec
      ( PlayerEffect.StateCoinFlip
          StatedFlip.MkStatedFlip
            { StatedFlip.face = Just CoinFace.Heads,
              StatedFlip.wins = True,
              StatedFlip.firstEachTurn = True
            }
      )
      " {\"type\":\"StateCoinFlip\",\"value\":{\"face\":{\"type\":\"Heads\"},\"wins\":true,\"firstEachTurn\":true}} "
  -- CR 706.2 as Clam-I-Am prints it, and the wire form
  -- data/cards/clam-i-am.json writes.
  Spec.it s "ModifyDieRoll, Clam-I-Am's reroll" $
    Common.assertCodec
      s
      PlayerEffect.codec
      ( PlayerEffect.ModifyDieRoll
          ModifiedRoll.MkModifiedRoll
            { ModifiedRoll.sides = Just 6,
              ModifiedRoll.natural = Just 3,
              ModifiedRoll.modifier = RollModifier.Reroll,
              ModifiedRoll.cost = Nothing,
              ModifiedRoll.limit = PermissionLimit.Unlimited
            }
      )
      " {\"type\":\"ModifyDieRoll\",\"value\":{\"sides\":6,\"natural\":3,\"modifier\":{\"type\":\"Reroll\"}}} "
  -- CR 701.38d as Brago's Representative prints it, and the wire form
  -- data/cards/bragos-representative.json writes.
  Spec.it s "AdditionalVotes, Brago's Representative's one" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.AdditionalVotes (ExtraVotes.Mandatory 1))
      " {\"type\":\"AdditionalVotes\",\"value\":{\"type\":\"Mandatory\",\"value\":1}} "
  -- CR 701.38d as Ballot Broker prints it, and the wire form
  -- data/cards/ballot-broker.json writes.
  Spec.it s "AdditionalVotes, Ballot Broker's optional one" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.AdditionalVotes (ExtraVotes.Optional 1))
      " {\"type\":\"AdditionalVotes\",\"value\":{\"type\":\"Optional\",\"value\":1}} "
  -- CR 701.25b as Enhanced Surveillance prints it, and the wire form
  -- data/cards/enhanced-surveillance.json writes.
  Spec.it s "AdditionalSurveilCards, Enhanced Surveillance's two" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.AdditionalSurveilCards 2)
      " {\"type\":\"AdditionalSurveilCards\",\"value\":2} "
  -- CR 702.85b as Averna, the Chaos Bloom prints it, and the wire form
  -- data/cards/averna-the-chaos-bloom.json writes.
  Spec.it s "PutTappedAsYouCascade, Averna's land card" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.PutTappedAsYouCascade (Filter.HasCardType CardType.Land))
      " {\"type\":\"PutTappedAsYouCascade\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}} "
  -- CR 119.7 as Giant Cindermaw prints it, and the wire form
  -- data/cards/giant-cindermaw.json writes.
  Spec.it s "CantGainLife, Giant Cindermaw's restriction" $
    Common.assertCodec
      s
      PlayerEffect.codec
      PlayerEffect.CantGainLife
      " {\"type\":\"CantGainLife\"} "
  -- CR 119.8, the other half of Platinum Emperion's one printed sentence
  -- (data/cards/platinum-emperion.json).
  Spec.it s "CantLoseLife, Platinum Emperion's restriction" $
    Common.assertCodec
      s
      PlayerEffect.codec
      PlayerEffect.CantLoseLife
      " {\"type\":\"CantLoseLife\"} "
  -- CR 104.2b, Abyssal Persecutor's "you can't win the game"
  -- (data/cards/abyssal-persecutor.json).
  Spec.it s "Precluded, Abyssal Persecutor's restriction" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.Precluded GameOutcome.Win)
      " {\"type\":\"Precluded\",\"value\":{\"type\":\"Win\"}} "
  -- CR 400.2, a revealed hand.
  Spec.it s "Shows, a hand to every player" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.Shows (Shows.MkShows ShownCards.Hand Audience.Everyone))
      " {\"type\":\"Shows\",\"value\":{\"cards\":{\"type\":\"Hand\"},\"to\":{\"type\":\"Everyone\"}}} "
  Spec.it s "RevealsDraw, Rowen's reveal" $
    Common.assertCodec
      s
      PlayerEffect.codec
      (PlayerEffect.RevealsDraw (DrawReveal.MkDrawReveal RevealObligation.Mandatory (Just 1)))
      " {\"type\":\"RevealsDraw\",\"value\":{\"obligation\":{\"type\":\"Mandatory\"},\"nth\":1}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerEffect.codec
