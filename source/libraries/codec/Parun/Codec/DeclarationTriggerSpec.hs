module Parun.Codec.DeclarationTriggerSpec where

import qualified Parun.Codec.DeclarationTrigger as DeclarationTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackCount as AttackCount
import qualified Parun.Types.DeclarationTrigger as DeclarationTrigger
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Subtype as Subtype

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DeclarationTrigger" $ do
  -- Boggart Prankster's "whenever you attack".
  Spec.it s "no count writes no key" $
    Common.assertCodec
      s
      DeclarationTrigger.codec
      (DeclarationTrigger.MkDeclarationTrigger PlayerRelation.You Nothing)
      " {\"player\":\"You\"} "
  -- Hermes, Overseer of Elpis' "whenever you attack with one or more Birds".
  Spec.it s "a count writes its key" $
    Common.assertCodec
      s
      DeclarationTrigger.codec
      (DeclarationTrigger.MkDeclarationTrigger PlayerRelation.Opponent (Just (AttackCount.MkAttackCount 1 (Filter.HasSubtype Subtype.Bird))))
      " {\"player\":\"Opponent\",\"attackers\":{\"floor\":1,\"filter\":{\"type\":\"HasSubtype\",\"value\":\"Bird\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DeclarationTrigger.codec
