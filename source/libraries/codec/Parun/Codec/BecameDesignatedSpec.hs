module Parun.Codec.BecameDesignatedSpec where

import qualified Parun.Codec.BecameDesignated as BecameDesignated
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BecameDesignated as BecameDesignated
import qualified Parun.Types.Designation as Designation
import qualified Parun.Types.ObjectId as ObjectId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.BecameDesignated" $ do
  -- CR 701's designations.
  Spec.it s "MkBecameDesignated, both keys" $
    Common.assertCodec
      s
      BecameDesignated.codec
      ( BecameDesignated.MkBecameDesignated
          { BecameDesignated.designation = Designation.Renowned,
            BecameDesignated.object = ObjectId.MkObjectId 1
          }
      )
      " {\"designation\":{\"type\":\"Renowned\"},\"object\":1} "
  Spec.it s "has a schema" $ Common.assertHasSchema s BecameDesignated.codec
