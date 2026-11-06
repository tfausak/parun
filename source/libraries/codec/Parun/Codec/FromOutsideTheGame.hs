{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.FromOutsideTheGame where

import qualified Data.Set as Set
import qualified Parun.Codec.DifferentIn as DifferentIn
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.OutsideDestination as OutsideDestination
import qualified Parun.Codec.OutsidePick as OutsidePick
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.FromOutsideTheGame as FromOutsideTheGame

-- | A bare object keyed by the record's field names.

-- Every key is required, where Parun.Codec.Search defaults its flags. The
-- reason is which way an absent key would read: each of these is a clause of
-- the printed sentence that every producer STATES, so a default would have to
-- pick the common spelling -- one card, True for the reveal, the hand for the
-- destination -- and a card file that simply omitted the key would then print a
-- sentence its card does not (Death Wish reveals nothing; The Raven's Warning
-- names the library; Research brings up to four). Writing the key out in every
-- card file that wishes is a cheap price for that not being possible.
--
-- `differentIn` and `pick` are defaulted for the same reason read the other
-- way: the absent key is the sentence that does not print the clause, as for
-- Parun.Codec.Search's flags.
codec :: Codec.Codec FromOutsideTheGame.FromOutsideTheGame
codec = Fields.object $ do
  count <- Fields.required "count" Common.natural FromOutsideTheGame.count
  upTo <- Fields.required "upTo" Common.boolean FromOutsideTheGame.upTo
  destination <- Fields.required "destination" OutsideDestination.codec FromOutsideTheGame.destination
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) FromOutsideTheGame.filter
  reveal <- Fields.required "reveal" Common.boolean FromOutsideTheGame.reveal
  differentIn <- Fields.defaulted "differentIn" Set.empty (Common.set DifferentIn.codec) FromOutsideTheGame.differentIn
  pick <- Fields.defaulted "pick" Nothing (Common.maybe OutsidePick.codec) FromOutsideTheGame.pick
  pure
    FromOutsideTheGame.MkFromOutsideTheGame
      { FromOutsideTheGame.count = count,
        FromOutsideTheGame.upTo = upTo,
        FromOutsideTheGame.destination = destination,
        FromOutsideTheGame.filter = filter_,
        FromOutsideTheGame.reveal = reveal,
        FromOutsideTheGame.differentIn = differentIn,
        FromOutsideTheGame.pick = pick
      }
