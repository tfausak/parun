module Parun.Codec.AimedAtSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.AimedAt as AimedAt
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AimedAt as AimedAt
import qualified Parun.Types.AimedPlayers as AimedPlayers
import qualified Parun.Types.AttackTargetKind as AttackTargetKind
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AimedAt" $ do
  Spec.it s "MkAimedAt, both keys" $
    Common.assertCodec
      s
      AimedAt.codec
      ( AimedAt.MkAimedAt
          { AimedAt.defenders = AimedPlayers.Scoped (PlayerScope.Related PlayerRelation.You),
            AimedAt.kinds = Set.fromList [AttackTargetKind.OfPlayer, AttackTargetKind.OfPlaneswalker]
          }
      )
      " {\"defenders\":{\"type\":\"Scoped\",\"value\":{\"type\":\"You\"}},\"kinds\":[{\"type\":\"OfPlayer\"},{\"type\":\"OfPlaneswalker\"}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AimedAt.codec
