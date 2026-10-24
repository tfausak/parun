module Parun.Codec.LeftTheGameSpec where

import qualified Parun.Codec.LeftTheGame as LeftTheGame
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LeftTheGame as LeftTheGame
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LeftTheGame" $ do
  -- CR 729.4a: a card a subgame took out of a main-game graveyard.
  Spec.it s "MkLeftTheGame, both keys" $
    Common.assertCodec
      s
      LeftTheGame.codec
      ( LeftTheGame.MkLeftTheGame
          { LeftTheGame.object = ObjectId.MkObjectId 7,
            LeftTheGame.from = Zone.Graveyard
          }
      )
      " {\"object\":7,\"from\":{\"type\":\"Graveyard\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LeftTheGame.codec
