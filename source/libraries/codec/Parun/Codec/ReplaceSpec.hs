module Parun.Codec.ReplaceSpec where

import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.Replace as Replace
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.DestructionR as DestructionR
import qualified Parun.Types.DestructionRewrite as DestructionRewrite
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Replace as Replace
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.ReplacementOrigin as ReplacementOrigin
import qualified Parun.Types.Uses as Uses

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Replace" $ do
  -- The effect codec the card boundary would pass in (CR 615.5's riders ride
  -- the DamageR arm underneath).
  let codec = Replace.codec Card.codec (GrantedAbility.codec Card.codec) (Effect.codec Card.codec (GrantedAbility.codec Card.codec))
  -- CR 614.3: the unconditional case, which is most of them. The positional
  -- payload this replaces wrote the absent condition as an explicit null.
  Spec.it s "MkReplace, condition elided" $
    Common.assertCodec
      s
      codec
      ( Replace.MkReplace
          { Replace.duration = Duration.UntilEndOfTurn,
            Replace.uses = Uses.Once,
            Replace.origin = ReplacementOrigin.Other,
            Replace.condition = Nothing,
            Replace.effect = ReplacementEffect.DestructionR (DestructionR.MkDestructionR Nothing DestructionRewrite.Regenerate)
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"uses\":{\"type\":\"Once\"},\"origin\":{\"type\":\"Other\"},\"effect\":{\"type\":\"DestructionR\",\"value\":{\"rewrite\":{\"type\":\"Regenerate\"}}}} "
  -- CR 614.15 / 614.1: Galvanic Blast's metalcraft clause, the case that writes
  -- the key.
  Spec.it s "MkReplace, condition written" $
    Common.assertCodec
      s
      codec
      ( Replace.MkReplace
          { Replace.duration = Duration.UntilEndOfTurn,
            Replace.uses = Uses.Once,
            Replace.origin = ReplacementOrigin.SelfReplacement,
            Replace.condition = Just (Condition.Compares (Compares.MkCompares (Quantity.Literal 3) Comparison.AtLeast (Quantity.Literal 3))),
            Replace.effect = ReplacementEffect.DestructionR (DestructionR.MkDestructionR Nothing DestructionRewrite.Regenerate)
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"uses\":{\"type\":\"Once\"},\"origin\":{\"type\":\"SelfReplacement\"},\"condition\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Literal\",\"value\":3},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":3}}},\"effect\":{\"type\":\"DestructionR\",\"value\":{\"rewrite\":{\"type\":\"Regenerate\"}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
