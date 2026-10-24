{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TokenPattern where

import qualified Parun.Codec.ControllerRelation as ControllerRelation
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TokenPattern as TokenPattern

-- | CR 109.5 reads a controller relation against the effect's source; "anyone's"
-- is the unrestricted reading, so it is what a pattern that says nothing means.
defaultWhose :: ControllerRelation.ControllerRelation
defaultWhose = ControllerRelation.Related PlayerRelation.AnyPlayer

codec :: Codec.Codec TokenPattern.TokenPattern
codec = Fields.object $ do
  whose <- Fields.defaulted "whose" defaultWhose ControllerRelation.codec TokenPattern.whose
  -- CR 111.1: elided is ANY token -- Doubling Season's "one or more tokens".
  whatToken <- Fields.defaulted "whatToken" (Filter.And []) (Filter.codec Keyword.codec) TokenPattern.whatToken
  pure
    TokenPattern.MkTokenPattern
      { TokenPattern.whose = whose,
        TokenPattern.whatToken = whatToken
      }
