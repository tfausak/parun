module Parun.Codec.EntryLinkSpec where

import qualified Parun.Codec.EntryLink as EntryLink
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.EntryLink as EntryLink
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EntryLink" $ do
  Spec.it s "MkEntryLink, the source's own abilities" $
    Common.assertCodec
      s
      EntryLink.codec
      (EntryLink.MkEntryLink {EntryLink.source = ObjectId.MkObjectId 7, EntryLink.acquisition = Acquisition.Own})
      " {\"source\":7} "

  Spec.it s "MkEntryLink, abilities a copy effect gave it" $
    Common.assertCodec
      s
      EntryLink.codec
      (EntryLink.MkEntryLink {EntryLink.source = ObjectId.MkObjectId 7, EntryLink.acquisition = Acquisition.Copied (Timestamp.MkTimestamp 3)})
      " {\"source\":7,\"acquisition\":{\"type\":\"Copied\",\"value\":3}} "

  Spec.it s "has a schema" $
    Common.assertHasSchema s EntryLink.codec
