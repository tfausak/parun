module Parun.Codec.SourceChoicesSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.SourceChoices as SourceChoices
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.Color as Color
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.SourceChoices as SourceChoices
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SourceChoices" $ do
  Spec.it s "nothing chosen" $
    Common.assertCodec
      s
      SourceChoices.codec
      SourceChoices.MkSourceChoices
        { SourceChoices.names = Map.empty,
          SourceChoices.colors = Set.empty,
          SourceChoices.subtype = Nothing,
          SourceChoices.number = Nothing,
          SourceChoices.acquisition = Acquisition.Own
        }
      " {} "
  Spec.it s "a name, a colour, a subtype and a number" $
    Common.assertCodec
      s
      SourceChoices.codec
      SourceChoices.MkSourceChoices
        { SourceChoices.names = Map.singleton (PlayerId.MkPlayerId 4) (CardName.MkCardName (Text.pack "Shock")),
          SourceChoices.colors = Set.singleton Color.Red,
          SourceChoices.subtype = Just Subtype.Goblin,
          SourceChoices.number = Just 5,
          SourceChoices.acquisition = Acquisition.Copied (Timestamp.MkTimestamp 3)
        }
      " {\"names\":{\"4\":\"Shock\"},\"colors\":[\"Red\"],\"subtype\":\"Goblin\",\"number\":5,\"acquisition\":{\"type\":\"Copied\",\"value\":3}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s SourceChoices.codec
