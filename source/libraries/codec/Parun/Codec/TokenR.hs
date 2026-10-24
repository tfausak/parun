{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TokenR where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Scaling as Scaling
import qualified Parun.Codec.TokenPattern as TokenPattern
import qualified Parun.Codec.TokenPlus as TokenPlus
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TokenR as TokenR

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464).
--
-- The card codec is a PARAMETER for Parun.Codec.Create's reason: `plus` is card
-- data nested inside card data.
codec :: (Typeable.Typeable card, Eq card) => Codec.Codec card -> Codec.Codec (TokenR.TokenR card)
codec cardCodec = Fields.object $ do
  matching <- Fields.required "matching" TokenPattern.codec TokenR.matching
  scaling <- Fields.defaulted "scaling" Nothing (Common.maybe Scaling.codec) TokenR.scaling
  plus <- Fields.defaulted "plus" Nothing (Common.maybe (TokenPlus.codec cardCodec)) TokenR.plus
  pure
    TokenR.MkTokenR
      { TokenR.matching = matching,
        TokenR.scaling = scaling,
        TokenR.plus = plus
      }
