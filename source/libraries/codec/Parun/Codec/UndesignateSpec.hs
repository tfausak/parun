module Parun.Codec.UndesignateSpec where

import qualified Parun.Codec.Undesignate as Undesignate
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Designation as Designation
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Undesignate as Undesignate

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Undesignate" $ do
  -- CR 723.3b: the named permanents lose this designation.
  Spec.it s "MkUndesignate, the two required keys" $
    Common.assertCodec
      s
      Undesignate.codec
      ( Undesignate.MkUndesignate
          { Undesignate.designation = Designation.Prepared,
            Undesignate.ref = ObjectRef.EachMatching (Filter.HasCardType CardType.Creature)
          }
      )
      " {\"designation\":\"Prepared\",\"ref\":{\"type\":\"EachMatching\",\"value\":{\"type\":\"HasCardType\",\"value\":\"Creature\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Undesignate.codec
