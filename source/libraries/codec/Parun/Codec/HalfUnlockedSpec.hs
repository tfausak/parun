module Parun.Codec.HalfUnlockedSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.HalfUnlocked as HalfUnlocked
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.HalfUnlocked as HalfUnlocked
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.HalfUnlocked" $ do
  -- CR 709.5e, with CR 709.5h's actor and CR 709.5i's completion flag. The id
  -- and the player are different numbers, so a codec that crossed the two fields
  -- would not round-trip.
  Spec.it s "MkHalfUnlocked, a door that completes the card" $
    Common.assertCodec
      s
      HalfUnlocked.codec
      ( HalfUnlocked.MkHalfUnlocked
          { HalfUnlocked.object = ObjectId.MkObjectId 1,
            HalfUnlocked.actor = PlayerId.MkPlayerId 2,
            HalfUnlocked.name = CardName.MkCardName (Text.pack "Trapped Entryway"),
            HalfUnlocked.fully = True
          }
      )
      " {\"object\":1,\"actor\":2,\"name\":\"Trapped Entryway\",\"fully\":true} "
  -- The flag defaults to nothing: it is REQUIRED, since False is a real answer
  -- (a door that opened but left the other locked) rather than an absence.
  Spec.it s "MkHalfUnlocked, a door that does not" $
    Common.assertCodec
      s
      HalfUnlocked.codec
      ( HalfUnlocked.MkHalfUnlocked
          { HalfUnlocked.object = ObjectId.MkObjectId 1,
            HalfUnlocked.actor = PlayerId.MkPlayerId 2,
            HalfUnlocked.name = CardName.MkCardName (Text.pack "Trapped Entryway"),
            HalfUnlocked.fully = False
          }
      )
      " {\"object\":1,\"actor\":2,\"name\":\"Trapped Entryway\",\"fully\":false} "
  Spec.it s "has a schema" $ Common.assertHasSchema s HalfUnlocked.codec
