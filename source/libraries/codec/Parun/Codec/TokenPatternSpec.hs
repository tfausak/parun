module Parun.Codec.TokenPatternSpec where

import qualified Parun.Codec.TokenPattern as TokenPattern
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TokenPattern as TokenPattern

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TokenPattern" $ do
  Spec.it s "MkTokenPattern" $
    Common.assertCodec
      s
      TokenPattern.codec
      TokenPattern.MkTokenPattern {TokenPattern.whose = ControllerRelation.Related PlayerRelation.You, TokenPattern.whatToken = Filter.And []}
      " {\"whose\":{\"type\":\"You\"}} "
  -- CR 111.1: Queen Allenal of Ruadach's "creature tokens".
  Spec.it s "a pattern naming what the token is" $
    Common.assertCodec
      s
      TokenPattern.codec
      TokenPattern.MkTokenPattern {TokenPattern.whose = ControllerRelation.Related PlayerRelation.You, TokenPattern.whatToken = Filter.HasCardType CardType.Creature}
      " {\"whose\":{\"type\":\"You\"},\"whatToken\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- CR 109.5: Related AnyPlayer is what a pattern that says nothing about the
  -- controller means, so the sole field's key is omitted.
  Spec.it s "an all-default value omits every optional key" $
    Common.assertCodec
      s
      TokenPattern.codec
      TokenPattern.MkTokenPattern {TokenPattern.whose = ControllerRelation.Related PlayerRelation.AnyPlayer, TokenPattern.whatToken = Filter.And []}
      " {} "
  Spec.it s "has a schema" $ Common.assertHasSchema s TokenPattern.codec
