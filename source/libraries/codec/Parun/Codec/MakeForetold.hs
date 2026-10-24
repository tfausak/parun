{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.MakeForetold where

import qualified Parun.Codec.ManaCost as ManaCost
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.MakeForetold as MakeForetold

-- | The cards are required and CR 702.143d's cost defaults to absent: rule
-- 702.143d's second sentence is a "may", and a card that states only the first
-- (The Foretold Soldier) leaves the exiled card its own printed foretell cost.
codec :: Codec.Codec MakeForetold.MakeForetold
codec = Fields.object $ do
  cards <- Fields.required "cards" ObjectRef.codec MakeForetold.cards
  manaCostReducedBy <- Fields.defaulted "manaCostReducedBy" Nothing (Common.maybe ManaCost.codec) MakeForetold.manaCostReducedBy
  pure
    MakeForetold.MkMakeForetold
      { MakeForetold.cards = cards,
        MakeForetold.manaCostReducedBy = manaCostReducedBy
      }
