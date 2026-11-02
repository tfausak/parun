module Parun.Codec.EntryOriginSpec where

import qualified Parun.Codec.EntryOrigin as EntryOrigin
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.EntryOrigin as EntryOrigin
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EntryOrigin" $ do
  Spec.it s "a card in a graveyard" $
    Common.assertCodec
      s
      EntryOrigin.codec
      EntryOrigin.MkEntryOrigin
        { EntryOrigin.zone = Zone.Graveyard,
          EntryOrigin.holder = Just (PlayerId.MkPlayerId 1),
          EntryOrigin.index = 2
        }
      " {\"holder\":1,\"index\":2,\"zone\":{\"type\":\"Graveyard\"}} "
  Spec.it s "a card in exile" $
    Common.assertCodec
      s
      EntryOrigin.codec
      EntryOrigin.MkEntryOrigin
        { EntryOrigin.zone = Zone.Exile,
          EntryOrigin.holder = Nothing,
          EntryOrigin.index = 0
        }
      " {\"zone\":{\"type\":\"Exile\"}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s EntryOrigin.codec
