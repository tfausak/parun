module Pawl.Codec.ExtraVotesSpec where

import qualified Pawl.Codec.ExtraVotes as ExtraVotes
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ExtraVotes as ExtraVotes

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ExtraVotes" $ do
  Spec.it s "Mandatory" $
    Common.assertCodec s ExtraVotes.codec (ExtraVotes.Mandatory 1) " {\"type\":\"Mandatory\",\"value\":1} "
  Spec.it s "Optional" $
    Common.assertCodec s ExtraVotes.codec (ExtraVotes.Optional 2) " {\"type\":\"Optional\",\"value\":2} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ExtraVotes.codec
