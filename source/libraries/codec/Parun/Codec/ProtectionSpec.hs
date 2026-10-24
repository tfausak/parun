module Parun.Codec.ProtectionSpec where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Protection as Protection
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Protection as Protection
import qualified Parun.Types.Subtype as Subtype

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (Protection.Protection Keyword.Keyword)
codec = Protection.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Protection" $ do
  -- CR 702.16a's quality alone, which is what all but one printing states.
  Spec.it s "MkProtection" $
    Common.assertCodec
      s
      codec
      Protection.MkProtection {Protection.quality = Filter.HasColor Color.Black, Protection.spares = Nothing}
      " {\"quality\":{\"type\":\"HasColor\",\"value\":{\"type\":\"Black\"}},\"spares\":null} "
  -- CR 702.16n: Spectra Ward's "this effect doesn't remove Auras".
  Spec.it s "MkProtection carries CR 702.16n's exception" $
    Common.assertCodec
      s
      codec
      Protection.MkProtection {Protection.quality = Filter.HasColor Color.Blue, Protection.spares = Just (Filter.HasSubtype Subtype.Aura)}
      " {\"quality\":{\"type\":\"HasColor\",\"value\":{\"type\":\"Blue\"}},\"spares\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Aura\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
