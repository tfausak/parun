module Parun.Codec.StaticAbilitySpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.GrantedAbility as GrantedAbility.Codec
import qualified Parun.Codec.StaticAbility as StaticAbility
import qualified Parun.Json.Value as Value
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Count as Count
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.SetBasePowerToughness as SetBasePowerToughness
import qualified Parun.Types.StaticAbility as StaticAbility
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.Zone as Zone

-- | The `card` parameter is instantiated at 'Text.Text', the posture
-- 'Parun.Codec.ActivatedAbilitySpec' takes: it is reached only through the
-- supplied card codec, so any type proves the shape.
codec :: Codec.Codec (StaticAbility.StaticAbility (GrantedAbility.GrantedAbility Text.Text))
codec = StaticAbility.codec (GrantedAbility.Codec.codec Common.text)

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.StaticAbility" $ do
  -- A single-part static ability, e.g. a keyword granter.
  Spec.it s "one part" $
    Common.assertCodec
      s
      codec
      (StaticAbility.MkStaticAbility Affected.Attached Nothing Set.empty Nothing Nothing (NonEmpty.singleton (Modification.GainKeyword Keyword.Flying)))
      " {\"affected\":{\"type\":\"Attached\"},\"modifications\":[{\"type\":\"GainKeyword\",\"value\":{\"type\":\"Flying\"}}]} "
  -- Humility's shape: several parts under one affected set (CR 613.6).
  Spec.it s "several parts" $
    Common.assertCodec
      s
      codec
      ( StaticAbility.MkStaticAbility
          Affected.Attached
          Nothing
          Set.empty
          Nothing
          Nothing
          (Modification.LoseAllAbilities NonEmpty.:| [Modification.SetBasePowerToughness (SetBasePowerToughness.MkSetBasePowerToughness (Just (Quantity.Literal 1)) (Just (Quantity.Literal 1)))])
      )
      " {\"affected\":{\"type\":\"Attached\"},\"modifications\":[{\"type\":\"LoseAllAbilities\"},{\"type\":\"SetBasePowerToughness\",\"value\":{\"power\":{\"type\":\"Literal\",\"value\":1},\"toughness\":{\"type\":\"Literal\",\"value\":1}}}]} "
  -- CR 604.2's "as long as" gate, Kird Ape's shape: the same ability plus a
  -- condition, so the key is present exactly when the clause is. The two cases
  -- above pin the absent half -- an encoder that always emitted the key would
  -- rewrite every card already committed.
  Spec.it s "an as-long-as condition" $
    Common.assertCodec
      s
      codec
      ( StaticAbility.MkStaticAbility
          Affected.Attached
          ( Just
              ( Condition.Compares
                  ( Compares.MkCompares
                      (Quantity.Count (Count.MkCount (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) (Filter.HasSubtype Subtype.Forest) Aggregation.Members))
                      Comparison.AtLeast
                      (Quantity.Literal 1)
                  )
              )
          )
          Set.empty
          Nothing
          Nothing
          (NonEmpty.singleton (Modification.GainKeyword Keyword.Flying))
      )
      " {\"affected\":{\"type\":\"Attached\"},\"condition\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Count\",\"value\":{\"scope\":{\"type\":\"InZone\",\"value\":{\"zone\":{\"type\":\"Battlefield\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}}}},\"filter\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Forest\"}},\"aggregation\":{\"type\":\"Members\"}}},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":1}}},\"modifications\":[{\"type\":\"GainKeyword\",\"value\":{\"type\":\"Flying\"}}]} "
  -- Titania's Song's second sentence: CR 604.2's other override, and optional
  -- for the condition's reason -- absent means the effect ends with its
  -- permanent, which is every other ability in the pool.
  Spec.it s "a leaves-the-battlefield duration" $
    Common.assertCodec
      s
      codec
      ( StaticAbility.MkStaticAbility
          Affected.Attached
          Nothing
          Set.empty
          (Just Duration.UntilEndOfTurn)
          Nothing
          (NonEmpty.singleton (Modification.GainKeyword Keyword.Flying))
      )
      " {\"affected\":{\"type\":\"Attached\"},\"lingers\":{\"type\":\"UntilEndOfTurn\"},\"modifications\":[{\"type\":\"GainKeyword\",\"value\":{\"type\":\"Flying\"}}]} "
  -- CR 113.6b's zone clause, Anger's shape. Optional for the condition's
  -- reason, and the two cases above pin the absent half: an encoder that always
  -- emitted the key would rewrite every card already committed.
  Spec.it s "a stated set of zones" $
    Common.assertCodec
      s
      codec
      ( StaticAbility.MkStaticAbility
          Affected.Attached
          Nothing
          (Set.fromList [Zone.Graveyard, Zone.Stack])
          Nothing
          Nothing
          (NonEmpty.singleton (Modification.GainKeyword Keyword.Flying))
      )
      " {\"affected\":{\"type\":\"Attached\"},\"functionsFrom\":[{\"type\":\"Graveyard\"},{\"type\":\"Stack\"}],\"modifications\":[{\"type\":\"GainKeyword\",\"value\":{\"type\":\"Flying\"}}]} "
  -- CR 613.1f: the name a LoseNamedAbility removal joins to. Optional for the
  -- condition's reason.
  Spec.it s "a name" $
    Common.assertCodec
      s
      codec
      ( StaticAbility.MkStaticAbility
          Affected.Attached
          Nothing
          Set.empty
          Nothing
          (Just (AbilityName.MkAbilityName (Text.pack "rally")))
          (NonEmpty.singleton (Modification.GainKeyword Keyword.Flying))
      )
      " {\"affected\":{\"type\":\"Attached\"},\"modifications\":[{\"type\":\"GainKeyword\",\"value\":{\"type\":\"Flying\"}}],\"name\":\"rally\"} "
  -- CR 613.6 is why a static ability is one affected set and one or more parts, so
  -- the wire format is an array -- and an array can be empty. An ability with
  -- no parts does nothing, which no card means, so it is a decode FAILURE
  -- rather than a permanent that quietly under-performs its own text.
  Spec.it s "an empty modifications array is rejected" $
    Spec.assertBool
      s
      ( either
          (const True)
          (const False)
          ( Codec.decode
              codec
              (Value.object [Value.pair "affected" (Common.tagged "Attached" Nothing), Value.pair "modifications" (Value.array [])])
          )
      )
      "an empty array does not decode"
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
