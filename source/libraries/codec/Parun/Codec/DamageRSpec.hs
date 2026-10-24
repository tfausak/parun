module Parun.Codec.DamageRSpec where

import qualified Data.Sequence as Seq
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.DamageR as DamageR
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamagePattern as DamagePattern
import qualified Parun.Types.DamageR as DamageR
import qualified Parun.Types.DamageRewrite as DamageRewrite
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DamageR" $ do
  -- CR 615.1: Fog prevents all combat damage.
  Spec.it s "MkDamageR" $
    Common.assertCodec
      s
      (DamageR.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      ( DamageR.MkDamageR
          { DamageR.matching =
              DamagePattern.MkDamagePattern
                { DamagePattern.whichKind = Just DamageKind.Combat,
                  DamagePattern.whatSource = Filter.And [],
                  DamagePattern.whatRecipient = Nothing,
                  DamagePattern.whoRecipient = Nothing,
                  DamagePattern.whichRecipient = Nothing,
                  DamagePattern.whichSource = Nothing,
                  DamagePattern.boundRecipient = Nothing
                },
            DamageR.rewrite = DamageRewrite.PreventAll,
            DamageR.riders = Seq.empty
          }
      )
      " {\"matching\":{\"whichKind\":{\"type\":\"Combat\"}},\"rewrite\":{\"type\":\"PreventAll\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (DamageR.codec (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
