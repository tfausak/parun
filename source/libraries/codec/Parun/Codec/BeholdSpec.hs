module Parun.Codec.BeholdSpec where

import qualified Parun.Codec.Behold as Behold
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Behold as Behold
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Subtype as Subtype

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (Behold.Behold Keyword.Keyword)
codec = Behold.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Behold" $ do
  -- Kindle the Inner Flame's three Elementals.
  Spec.it s "MkBehold" $
    Common.assertCodec
      s
      codec
      (Behold.MkBehold {Behold.count = 3, Behold.whichObjects = Filter.HasSubtype Subtype.Elemental})
      " {\"count\":3,\"whichObjects\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Elemental\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
