{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CreateEmblem where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CreateEmblem as CreateEmblem
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | The card codec is a PARAMETER, Parun.Codec.Create's posture: this arm is
-- where card data nests inside card data.
codec :: (Typeable.Typeable card) => Codec.Codec card -> Codec.Codec (CreateEmblem.CreateEmblem card)
codec cardCodec = Fields.object $ do
  card <- Fields.required "card" cardCodec CreateEmblem.card
  -- CR 114.2 under CR 109.5: elided is "you".
  player <- Fields.defaulted "player" (PlayerRef.Relative PlayerRelation.You) PlayerRef.codec CreateEmblem.player
  pure
    CreateEmblem.MkCreateEmblem
      { CreateEmblem.card = card,
        CreateEmblem.player = player
      }
