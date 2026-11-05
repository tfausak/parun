{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.UntilPaid where

import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerRef as PlayerRef.Type
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.UntilPaid as UntilPaid

-- | The default payer is CR 109.5's "you", the Licid wording.
codec :: Codec.Codec UntilPaid.UntilPaid
codec = Fields.object $ do
  payer <- Fields.defaulted "payer" (PlayerRef.Type.Relative PlayerRelation.You) PlayerRef.codec UntilPaid.payer
  cost <- Fields.required "cost" (Cost.codec Keyword.codec) UntilPaid.cost
  pure UntilPaid.MkUntilPaid {UntilPaid.payer = payer, UntilPaid.cost = cost}
