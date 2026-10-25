{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ChosenPermanents where

import qualified Data.Text as Text
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.HowMany as HowMany
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ChosenPermanents as ChosenPermanents
import qualified Parun.Types.HowMany as HowMany
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Zone as Zone

-- | A bare object keyed by the record's field names, the shape every other
-- 'Parun.Types.ObjectRef' payload record takes.
--
-- @chooser@, @count@ and @zone@ are defaulted, so the printed choice of one
-- permanent addressed to the resolving controller writes none of those keys.
--
-- The zone must be one CR 400.1 shares: a per-player zone's choice is
-- Parun.Types.ChosenCardInGraveyard's or ChosenCardInHand's, which say whose.
codec :: Codec.Codec ChosenPermanents.ChosenPermanents
codec = Fields.objectWith sharedZone $ do
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) ChosenPermanents.filter
  chooser <- Fields.defaulted "chooser" (PlayerRef.Relative PlayerRelation.You) PlayerRef.codec ChosenPermanents.chooser
  count <- Fields.defaulted "count" HowMany.one HowMany.codec ChosenPermanents.count
  zone <- Fields.defaulted "zone" Zone.Battlefield Zone.codec ChosenPermanents.zone
  pure
    ChosenPermanents.MkChosenPermanents
      { ChosenPermanents.filter = filter_,
        ChosenPermanents.chooser = chooser,
        ChosenPermanents.count = count,
        ChosenPermanents.zone = zone
      }

sharedZone :: ChosenPermanents.ChosenPermanents -> Either Text.Text ChosenPermanents.ChosenPermanents
sharedZone choice
  | Zone.shared (ChosenPermanents.zone choice) = Right choice
  | otherwise = Left (Text.pack ("ChosenPermanents: CR 400.1 gives each player their own " <> show (ChosenPermanents.zone choice)))
