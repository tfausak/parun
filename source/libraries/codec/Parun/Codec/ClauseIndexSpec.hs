module Parun.Codec.ClauseIndexSpec where

import qualified Data.Either as Either
import qualified Data.Text as Text
import qualified Parun.Codec.ClauseIndex as ClauseIndex
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ClauseIndex as ClauseIndex

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ClauseIndex" $ do
  Spec.it s "MkClauseIndex" $
    Common.assertCodec
      s
      ClauseIndex.codec
      (ClauseIndex.MkClauseIndex 2)
      " 2 "

  Spec.it s "has a schema" $
    Common.assertHasSchema s ClauseIndex.codec

  -- The wrapped type is Natural, so a negative number is a decode failure
  -- rather than a wrapped negative going through a partial fromInteger.
  Spec.it s "rejects a negative number" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " -1 ") >>= Codec.decode ClauseIndex.codec))
      "expected a decode failure"
