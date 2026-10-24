{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ChosenPermanents where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.HowMany as HowMany
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ChosenPermanents as ChosenPermanents
import qualified Parun.Types.HowMany as HowMany
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | A bare object keyed by the record's field names, the shape every other
-- 'Parun.Types.ObjectRef' payload record takes.
--
-- @chooser@ and @count@ are defaulted, so the printed choice of one permanent
-- addressed to the resolving controller writes neither key.
codec :: Codec.Codec ChosenPermanents.ChosenPermanents
codec = Fields.object $ do
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) ChosenPermanents.filter
  chooser <- Fields.defaulted "chooser" (PlayerRef.Relative PlayerRelation.You) PlayerRef.codec ChosenPermanents.chooser
  count <- Fields.defaulted "count" HowMany.one HowMany.codec ChosenPermanents.count
  pure
    ChosenPermanents.MkChosenPermanents
      { ChosenPermanents.filter = filter_,
        ChosenPermanents.chooser = chooser,
        ChosenPermanents.count = count
      }
