module Parun.Codec.HandActionSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.HandAction as HandAction
import qualified Parun.Json.Value as Value
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.HandAction as HandAction
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity

-- | The `card` parameter is instantiated at 'Text.Text' throughout, for
-- 'Parun.Codec.ClauseSpec''s reason: the codec reaches it only through the
-- supplied Effect codec, so any type proves the shape.
cardCodec :: Codec.Codec Text.Text
cardCodec = Common.text

codec :: Codec.Codec (HandAction.HandAction Text.Text)
codec = HandAction.codec cardCodec

toJson :: HandAction.HandAction Text.Text -> Value.Value
toJson = Codec.encode codec

fromJson :: Value.Value -> Either Text.Text (HandAction.HandAction Text.Text)
fromJson = Codec.decode codec

-- One constructor, so three cases: an ungated action (every card in the corpus
-- but one), CR 103.6's gate when present, and both fields defaulted away.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.HandAction" $ do
  Spec.it s "MkHandAction with one effect and no gate" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      (HandAction.MkHandAction Nothing [Effect.ExileHandThenDraw])
      " {\"effects\":[{\"type\":\"ExileHandThenDraw\"}]} "
  -- CR 103.1: Gemstone Caverns' "you're not the starting player", the whole
  -- reason this type is a record rather than a list of effects.
  Spec.it s "a gated action keeps its condition" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      ( HandAction.MkHandAction
          (Just (Condition.Compares (Compares.MkCompares (Quantity.IsStartingPlayer (PlayerRef.Relative PlayerRelation.You)) Comparison.Exactly (Quantity.Literal 0))))
          []
      )
      " {\"condition\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"IsStartingPlayer\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"comparison\":{\"type\":\"Exactly\"},\"threshold\":{\"type\":\"Literal\",\"value\":0}}}} "
  Spec.it s "both keys default away" $ do
    v <- Common.assertJson s " {} "
    Spec.assertEq s (fromJson v) (Right (HandAction.MkHandAction Nothing []))
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
