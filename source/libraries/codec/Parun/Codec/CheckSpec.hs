module Parun.Codec.CheckSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.Check as Check
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackersAre as AttackersAre.Type
import qualified Parun.Types.BlockersAre as BlockersAre.Type
import qualified Parun.Types.CardName as CardName.Type
import qualified Parun.Types.CardType as CardType.Type
import qualified Parun.Types.Check as Check.Type
import qualified Parun.Types.CountIs as CountIs.Type
import qualified Parun.Types.CounterKind as CounterKind.Type
import qualified Parun.Types.CountersAre as CountersAre.Type
import qualified Parun.Types.DamageIs as DamageIs.Type
import qualified Parun.Types.DefendersAre as DefendersAre.Type
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.KeywordsAre as KeywordsAre.Type
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.LifeIs as LifeIs.Type
import qualified Parun.Types.MonarchIs as MonarchIs.Type
import qualified Parun.Types.NamesAre as NamesAre.Type
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind.Type
import qualified Parun.Types.PlayerCountersAre as PlayerCountersAre.Type
import qualified Parun.Types.PowerToughnessIs as PowerToughnessIs.Type
import qualified Parun.Types.Reference as Reference.Type
import qualified Parun.Types.Subtype as Subtype.Type
import qualified Parun.Types.SubtypesAre as SubtypesAre.Type
import qualified Parun.Types.TapState as TapState.Type
import qualified Parun.Types.TappedIs as TappedIs.Type
import qualified Parun.Types.TypesAre as TypesAre.Type
import qualified Parun.Types.Zone as Zone.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Check" $ do
  Spec.it s "Life" $
    Common.assertCodec s Check.codec (Check.Type.Life (LifeIs.Type.MkLifeIs (Label.Type.MkLabel (Text.pack "bob")) 18)) " {\"Life\":{\"player\":\"bob\",\"life\":18}} "
  Spec.it s "Count" $
    Common.assertCodec s Check.codec (Check.Type.Count (CountIs.Type.MkCountIs (Label.Type.MkLabel (Text.pack "bob")) Zone.Type.Battlefield (CardName.Type.MkCardName (Text.pack "Goblin Piker")) 0)) " {\"Count\":{\"player\":\"bob\",\"zone\":\"Battlefield\",\"card\":\"Goblin Piker\",\"count\":0}} "
  Spec.it s "Damage" $
    Common.assertCodec s Check.codec (Check.Type.Damage (DamageIs.Type.MkDamageIs (Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "wall"))) 2)) " {\"Damage\":{\"object\":\"$wall\",\"damage\":2}} "
  Spec.it s "Tapped" $
    Common.assertCodec s Check.codec (Check.Type.Tapped (TappedIs.Type.MkTappedIs (Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "bear"))) TapState.Type.Untapped)) " {\"Tapped\":{\"object\":\"$bear\",\"tapped\":false}} "
  Spec.it s "Counters" $
    Common.assertCodec s Check.codec (Check.Type.Counters (CountersAre.Type.MkCountersAre (labelled "jace") CounterKind.Type.Loyalty 3)) " {\"Counters\":{\"object\":\"$jace\",\"kind\":{\"type\":\"Loyalty\"},\"count\":3}} "
  Spec.it s "Types" $
    Common.assertCodec s Check.codec (Check.Type.Types (TypesAre.Type.MkTypesAre (labelled "soldier") (Set.singleton CardType.Type.Creature))) " {\"Types\":{\"object\":\"$soldier\",\"types\":[\"Creature\"]}} "
  Spec.it s "Attackers" $
    Common.assertCodec s Check.codec (Check.Type.Attackers (AttackersAre.Type.MkAttackersAre (Map.singleton (labelled "bear") (labelled "bob")))) " {\"Attackers\":{\"attackers\":{\"$bear\":\"$bob\"}}} "
  Spec.it s "Blockers" $
    Common.assertCodec s Check.codec (Check.Type.Blockers (BlockersAre.Type.MkBlockersAre (labelled "bear") (Just (Set.singleton (labelled "wall"))))) " {\"Blockers\":{\"attacker\":\"$bear\",\"blockers\":[\"$wall\"]}} "
  Spec.it s "Defenders" $
    Common.assertCodec s Check.codec (Check.Type.Defenders (DefendersAre.Type.MkDefendersAre [Label.Type.MkLabel (Text.pack "bob")])) " {\"Defenders\":{\"players\":[\"bob\"]}} "
  Spec.it s "Monarch" $
    Common.assertCodec s Check.codec (Check.Type.Monarch (MonarchIs.Type.MkMonarchIs (Just (Label.Type.MkLabel (Text.pack "alice"))))) " {\"Monarch\":{\"player\":\"alice\"}} "
  Spec.it s "PowerToughness" $
    Common.assertCodec s Check.codec (Check.Type.PowerToughness (PowerToughnessIs.Type.MkPowerToughnessIs (labelled "bear") 3 3)) " {\"PowerToughness\":{\"object\":\"$bear\",\"power\":3,\"toughness\":3}} "
  Spec.it s "PlayerCounters" $
    Common.assertCodec s Check.codec (Check.Type.PlayerCounters (PlayerCountersAre.Type.MkPlayerCountersAre (Label.Type.MkLabel (Text.pack "bob")) PlayerCounterKind.Type.Energy 2)) " {\"PlayerCounters\":{\"player\":\"bob\",\"kind\":{\"type\":\"Energy\"},\"count\":2}} "
  Spec.it s "Names" $
    Common.assertCodec s Check.codec (Check.Type.Names (NamesAre.Type.MkNamesAre (labelled "clone") (Set.singleton (CardName.Type.MkCardName (Text.pack "Goblin Piker"))))) " {\"Names\":{\"object\":\"$clone\",\"names\":[\"Goblin Piker\"]}} "
  Spec.it s "Subtypes" $
    Common.assertCodec s Check.codec (Check.Type.Subtypes (SubtypesAre.Type.MkSubtypesAre (labelled "piker") (Set.singleton Subtype.Type.Goblin))) " {\"Subtypes\":{\"object\":\"$piker\",\"subtypes\":[\"Goblin\"]}} "
  Spec.it s "Keywords" $
    Common.assertCodec s Check.codec (Check.Type.Keywords (KeywordsAre.Type.MkKeywordsAre (labelled "bird") Keyword.Type.Flying 1)) " {\"Keywords\":{\"object\":\"$bird\",\"keyword\":{\"type\":\"Flying\"},\"count\":1}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Check.codec

labelled :: String -> Reference.Type.Reference
labelled = Reference.Type.Labelled . Label.Type.MkLabel . Text.pack
