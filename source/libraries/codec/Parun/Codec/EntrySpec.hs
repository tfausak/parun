module Parun.Codec.EntrySpec where

import qualified Data.Either as Either
import qualified Data.Text as Text
import qualified Parun.Codec.Entry as Entry
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Check as Check.Type
import qualified Parun.Types.Entry as Entry.Type
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.LifeIs as LifeIs.Type
import qualified Parun.Types.Move as Move.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Entry" $ do
  Spec.it s "a move is under do" $
    Common.assertCodec s Entry.codec (Entry.Type.Do Move.Type.Pass) " {\"do\":\"Pass\"} "
  Spec.it s "a refused move is under refuse" $
    Common.assertCodec s Entry.codec (Entry.Type.Refuse Move.Type.Pass) " {\"refuse\":\"Pass\"} "
  Spec.it s "a check is under check" $
    Common.assertCodec s Entry.codec (Entry.Type.Expect (Check.Type.Life (LifeIs.Type.MkLifeIs (Label.Type.MkLabel (Text.pack "bob")) 18))) " {\"check\":{\"Life\":{\"player\":\"bob\",\"life\":18}}} "
  Spec.it s "rejects two and none" $
    Spec.assertBool
      s
      (all (\t -> Either.isLeft (Common.parse (Text.pack t) >>= Codec.decode Entry.codec)) ["{}", "{\"do\":\"Pass\",\"check\":{\"Life\":{\"player\":\"bob\",\"life\":18}}}", "{\"do\":\"Pass\",\"refuse\":\"Pass\"}"])
      "expected each to fail"
  Spec.it s "has a schema" $
    Common.assertHasSchema s Entry.codec
