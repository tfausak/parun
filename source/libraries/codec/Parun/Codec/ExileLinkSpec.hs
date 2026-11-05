module Parun.Codec.ExileLinkSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ExileLink as ExileLink
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.ExileLink as ExileLink
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ExileLink" $ do
  Spec.it s "MkExileLink, an unnamed ability" $
    Common.assertCodec
      s
      ExileLink.codec
      (ExileLink.MkExileLink {ExileLink.source = ObjectId.MkObjectId 7, ExileLink.ability = Nothing, ExileLink.acquisition = Acquisition.Own})
      " {\"source\":7} "

  Spec.it s "MkExileLink, a named ability" $
    Common.assertCodec
      s
      ExileLink.codec
      (ExileLink.MkExileLink {ExileLink.source = ObjectId.MkObjectId 7, ExileLink.ability = Just (AbilityName.MkAbilityName (Text.pack "warden")), ExileLink.acquisition = Acquisition.Own})
      " {\"source\":7,\"ability\":\"warden\"} "

  Spec.it s "MkExileLink, an ability a copy effect gave it" $
    Common.assertCodec
      s
      ExileLink.codec
      (ExileLink.MkExileLink {ExileLink.source = ObjectId.MkObjectId 7, ExileLink.ability = Nothing, ExileLink.acquisition = Acquisition.Copied (Timestamp.MkTimestamp 3)})
      " {\"source\":7,\"acquisition\":{\"type\":\"Copied\",\"value\":3}} "

  Spec.it s "has a schema" $
    Common.assertHasSchema s ExileLink.codec
