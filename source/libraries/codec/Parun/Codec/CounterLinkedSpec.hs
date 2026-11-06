module Parun.Codec.CounterLinkedSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.CounterLinked as CounterLinked
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterLinked as CounterLinked
import qualified Parun.Types.CounterName as CounterName
import qualified Parun.Types.Keyword as Keyword

codec :: Codec.Codec (CounterLinked.CounterLinked Keyword.Keyword)
codec = CounterLinked.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterLinked" $ do
  Spec.it s "PutWith" $
    Common.assertCodec
      s
      codec
      (CounterLinked.PutWith (CounterKind.Named (CounterName.UnsafeMkCounterName (Text.pack "mire"))))
      " {\"type\":\"PutWith\",\"value\":{\"type\":\"Named\",\"value\":\"mire\"}} "
  Spec.it s "RemovedWith" $
    Common.assertCodec
      s
      codec
      (CounterLinked.RemovedWith CounterKind.PlusOnePlusOne)
      " {\"type\":\"RemovedWith\",\"value\":{\"type\":\"PlusOnePlusOne\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
