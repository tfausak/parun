{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CastOffer where

import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ManaSpending as ManaSpending
import qualified Parun.Codec.TurnUpEvent as TurnUpEvent
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CastOffer as CastOffer
import qualified Parun.Types.ManaSpending as ManaSpending.Type

codec :: Codec.Codec CastOffer.CastOffer
codec = Fields.object $ do
  transformed <- Fields.defaulted "transformed" False Common.boolean CastOffer.transformed
  withoutPayingManaCost <- Fields.defaulted "withoutPayingManaCost" False Common.boolean CastOffer.withoutPayingManaCost
  payingInstead <- Fields.defaulted "payingInstead" Nothing (Common.maybe (Cost.codec Keyword.codec)) CastOffer.payingInstead
  spending <- Fields.defaulted "spending" ManaSpending.Type.AsProduced ManaSpending.codec CastOffer.spending
  restriction <- Fields.defaulted "restriction" Nothing (Common.maybe (Filter.codec Keyword.codec)) CastOffer.restriction
  offeredBy <- Fields.defaulted "offeredBy" Nothing (Common.maybe Keyword.codec) CastOffer.offeredBy
  faceDown <- Fields.defaulted "faceDown" Nothing (Common.maybe (Common.set TurnUpEvent.codec)) CastOffer.faceDown
  payableFromSpent <- Fields.defaulted "payableFromSpent" False Common.boolean CastOffer.payableFromSpent
  reduction <- Fields.defaulted "reduction" 0 Common.natural CastOffer.reduction
  pure
    CastOffer.MkCastOffer
      { CastOffer.transformed = transformed,
        CastOffer.withoutPayingManaCost = withoutPayingManaCost,
        CastOffer.payingInstead = payingInstead,
        CastOffer.spending = spending,
        CastOffer.restriction = restriction,
        CastOffer.offeredBy = offeredBy,
        CastOffer.faceDown = faceDown,
        CastOffer.payableFromSpent = payableFromSpent,
        CastOffer.reduction = reduction
      }

-- | The value the codec elides entirely: an offer that transforms nothing,
-- applies no alternative cost, widens no payment and narrows no half is an
-- ordinary cast of the card (CR 712.11's default face, CR 601.2b's own
-- candidates, CR 118.14 unsaid, CR 709.3a's halves all offered, and no keyword
-- ability behind the cost, and nothing taken off it).
defaultValue :: CastOffer.CastOffer
defaultValue =
  CastOffer.MkCastOffer
    { CastOffer.transformed = False,
      CastOffer.withoutPayingManaCost = False,
      CastOffer.payingInstead = Nothing,
      CastOffer.spending = ManaSpending.Type.AsProduced,
      CastOffer.restriction = Nothing,
      CastOffer.offeredBy = Nothing,
      CastOffer.faceDown = Nothing,
      CastOffer.payableFromSpent = False,
      CastOffer.reduction = 0
    }
