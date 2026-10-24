module Parun.Codec.PrintedReplacementSpec where

import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.PrintedReplacement as PrintedReplacement
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.DestructionR as DestructionR
import qualified Parun.Types.DestructionRewrite as DestructionRewrite
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PrintedReplacement as PrintedReplacement
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PrintedReplacement" $ do
  -- The effect codec the card boundary would pass in (CR 615.5's riders ride
  -- the DamageR arm underneath).
  let codec = PrintedReplacement.codec Card.codec (GrantedAbility.codec Card.codec) (Effect.codec Card.codec (GrantedAbility.codec Card.codec))
  -- CR 604.2's unconditional case, which is every producer in the pool but one.
  Spec.it s "MkPrintedReplacement, condition elided" $
    Common.assertCodec
      s
      codec
      ( PrintedReplacement.MkPrintedReplacement
          { PrintedReplacement.condition = Nothing,
            PrintedReplacement.effect = ReplacementEffect.DestructionR (DestructionR.MkDestructionR Nothing DestructionRewrite.Regenerate),
            PrintedReplacement.functionsFrom = Set.empty,
            PrintedReplacement.name = Nothing
          }
      )
      " {\"effect\":{\"type\":\"DestructionR\",\"value\":{\"rewrite\":{\"type\":\"Regenerate\"}}}} "
  -- Jared Carthalion, True Heir's "while you're the monarch", the case that
  -- writes the key.
  Spec.it s "MkPrintedReplacement, condition written" $
    Common.assertCodec
      s
      codec
      ( PrintedReplacement.MkPrintedReplacement
          { PrintedReplacement.condition =
              Just
                ( Condition.Compares
                    ( Compares.MkCompares
                        (Quantity.IsMonarch (PlayerRef.Relative PlayerRelation.You))
                        Comparison.AtLeast
                        (Quantity.Literal 1)
                    )
                ),
            PrintedReplacement.effect = ReplacementEffect.DestructionR (DestructionR.MkDestructionR Nothing DestructionRewrite.Regenerate),
            PrintedReplacement.functionsFrom = Set.empty,
            PrintedReplacement.name = Nothing
          }
      )
      " {\"condition\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"IsMonarch\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":1}}},\"effect\":{\"type\":\"DestructionR\",\"value\":{\"rewrite\":{\"type\":\"Regenerate\"}}}} "
  -- Glittering Lion's "shield", the case that writes the OTHER optional key. Its
  -- own case rather than a rider on one above, because 'Fields.defaulted' decodes
  -- a mistyped key as Nothing with no error, and a nameless printed replacement
  -- is one a CR 613.1f removal silently cannot reach.
  Spec.it s "MkPrintedReplacement, name written" $
    Common.assertCodec
      s
      codec
      ( PrintedReplacement.MkPrintedReplacement
          { PrintedReplacement.condition = Nothing,
            PrintedReplacement.effect = ReplacementEffect.DestructionR (DestructionR.MkDestructionR Nothing DestructionRewrite.Regenerate),
            PrintedReplacement.functionsFrom = Set.empty,
            PrintedReplacement.name = Just (AbilityName.MkAbilityName (Text.pack "shield"))
          }
      )
      " {\"effect\":{\"type\":\"DestructionR\",\"value\":{\"rewrite\":{\"type\":\"Regenerate\"}}},\"name\":\"shield\"} "
  -- CR 113.6b's zone clause, Nexus of Fate's shape. Optional for the condition's
  -- reason, and the three cases above pin the absent half: an encoder that always
  -- emitted the key would rewrite every card already committed.
  Spec.it s "MkPrintedReplacement, a stated set of zones" $
    Common.assertCodec
      s
      codec
      ( PrintedReplacement.MkPrintedReplacement
          { PrintedReplacement.condition = Nothing,
            PrintedReplacement.effect = ReplacementEffect.DestructionR (DestructionR.MkDestructionR Nothing DestructionRewrite.Regenerate),
            PrintedReplacement.functionsFrom = Set.fromList [Zone.Graveyard, Zone.Stack],
            PrintedReplacement.name = Nothing
          }
      )
      " {\"effect\":{\"type\":\"DestructionR\",\"value\":{\"rewrite\":{\"type\":\"Regenerate\"}}},\"functionsFrom\":[{\"type\":\"Graveyard\"},{\"type\":\"Stack\"}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
