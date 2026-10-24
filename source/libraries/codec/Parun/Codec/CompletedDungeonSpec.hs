module Parun.Codec.CompletedDungeonSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.CompletedDungeon as CompletedDungeon
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CompletedDungeon as CompletedDungeon
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CompletedDungeon" $ do
  -- CR 309.7 asked of one dungeon by name -- a LEAF, so nothing here is a
  -- Quantity.
  Spec.it s "MkCompletedDungeon" $
    Common.assertCodec
      s
      CompletedDungeon.codec
      ( CompletedDungeon.MkCompletedDungeon
          { CompletedDungeon.player = PlayerRef.Relative PlayerRelation.AnyPlayer,
            CompletedDungeon.dungeon = CardName.MkCardName (Text.pack "Tomb of Annihilation")
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}},\"dungeon\":\"Tomb of Annihilation\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CompletedDungeon.codec
