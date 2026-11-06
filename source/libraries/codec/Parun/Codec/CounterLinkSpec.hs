module Parun.Codec.CounterLinkSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.CounterLink as CounterLink
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterLink as CounterLink
import qualified Parun.Types.CounterLinked as CounterLinked
import qualified Parun.Types.CounterName as CounterName
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterLink" $ do
  Spec.it s "MkCounterLink, the source's own abilities" $
    Common.assertCodec
      s
      CounterLink.codec
      (CounterLink.MkCounterLink {CounterLink.source = ObjectId.MkObjectId 7, CounterLink.acquisition = Acquisition.Own, CounterLink.moved = CounterLinked.PutWith (CounterKind.Named (CounterName.UnsafeMkCounterName (Text.pack "mire")))})
      " {\"source\":7,\"moved\":{\"type\":\"PutWith\",\"value\":{\"type\":\"Named\",\"value\":\"mire\"}}} "

  Spec.it s "MkCounterLink, abilities a copy effect gave it" $
    Common.assertCodec
      s
      CounterLink.codec
      (CounterLink.MkCounterLink {CounterLink.source = ObjectId.MkObjectId 7, CounterLink.acquisition = Acquisition.Copied (Timestamp.MkTimestamp 3), CounterLink.moved = CounterLinked.RemovedWith (CounterKind.Named (CounterName.UnsafeMkCounterName (Text.pack "mire")))})
      " {\"source\":7,\"acquisition\":{\"type\":\"Copied\",\"value\":3},\"moved\":{\"type\":\"RemovedWith\",\"value\":{\"type\":\"Named\",\"value\":\"mire\"}}} "

  Spec.it s "has a schema" $
    Common.assertHasSchema s CounterLink.codec
