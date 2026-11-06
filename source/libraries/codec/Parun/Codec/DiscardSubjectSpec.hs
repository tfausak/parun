module Parun.Codec.DiscardSubjectSpec where

import qualified Parun.Codec.DiscardSubject as DiscardSubject
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.DiscardSubject as DiscardSubject
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerActsOn as PlayerActsOn
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DiscardSubject" $ do
  Spec.it s "Self" $
    Common.assertCodec
      s
      DiscardSubject.codec
      DiscardSubject.Self
      " {\"type\":\"Self\"} "
  -- Waste Not's "whenever an opponent discards a creature card".
  Spec.it s "Discarder" $
    Common.assertCodec
      s
      DiscardSubject.codec
      (DiscardSubject.Discarder (PlayerActsOn.MkPlayerActsOn PlayerRelation.Opponent (Filter.HasCardType CardType.Creature)))
      " {\"type\":\"Discarder\",\"value\":{\"player\":\"Opponent\",\"filter\":{\"type\":\"HasCardType\",\"value\":\"Creature\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DiscardSubject.codec
