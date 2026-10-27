{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Search where

import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Parun.Codec.DifferentIn as DifferentIn
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SearchDestination as SearchDestination
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Search as Search
import qualified Parun.Types.Zone as Zone.Type

-- | A bare object keyed by the record's field names. Naming them is the point:
-- 'Search.searcher' and 'Search.owner' are both a PlayerRef, so a positional
-- payload let a card file swap who looks with whose zones are looked at.
codec :: Codec.Codec Search.Search
codec = Fields.object $ do
  searcher <- Fields.required "searcher" PlayerRef.codec Search.searcher
  owner <- Fields.required "owner" PlayerRef.codec Search.owner
  -- Defaulted rather than required, for upTo's reason: an absent key is a card
  -- that names no zone, which every card file already written means as a
  -- library.
  zones <- Fields.defaulted "zones" (Set.singleton Zone.Type.Library) (Common.set Zone.codec) Search.zones
  -- Defaulted: an absent key is a search that does not reach outside the game,
  -- which is every card file already written.
  outsideTheGame <- Fields.defaulted "outsideTheGame" False Common.boolean Search.outsideTheGame
  -- Defaulted: an absent key is a card whose places are joined by "and", or
  -- that names only one.
  andOr <- Fields.defaulted "andOr" False Common.boolean Search.andOr
  -- Required but nullable, rather than defaulted-absent: a null is a card
  -- printing "any number of", and an absent key is a card file that forgot the
  -- count. Defaulting would read the second as the first.
  quantity <- Fields.required "quantity" (Common.maybe Quantity.codec) Search.quantity
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) Search.filter
  -- Defaulted: an absent key is an instruction of one description, which is
  -- nearly every card file.
  descriptions <- Fields.defaulted "descriptions" Seq.empty (Common.seq (Filter.codec Keyword.codec)) Search.descriptions
  -- Defaulted rather than required: an absent key is a card that does not print
  -- "up to", which is the ordinary case, and the reading every card file already
  -- written gets.
  upTo <- Fields.defaulted "upTo" False Common.boolean Search.upTo
  destination <- Fields.required "destination" SearchDestination.codec Search.destination
  -- Defaulted rather than required: an absent key is a card whose "it" is its own
  -- source, which is every card file already written and the reading CR 113.7
  -- gives a search that names no slot.
  subject <- Fields.defaulted "subject" Nothing (Common.maybe SlotName.codec) Search.subject
  -- Defaulted: an absent key is a search whose finds no later clause names.
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) Search.slot
  -- Defaulted: an absent key is a search that prints no "with different ...",
  -- which is most card files.
  differentIn <- Fields.defaulted "differentIn" Set.empty (Common.set DifferentIn.codec) Search.differentIn
  -- Defaulted: an absent key is a search that does not print "exactly",
  -- which is nearly every card file.
  exactly <- Fields.defaulted "exactly" False Common.boolean Search.exactly
  pure
    Search.MkSearch
      { Search.searcher = searcher,
        Search.owner = owner,
        Search.zones = zones,
        Search.outsideTheGame = outsideTheGame,
        Search.quantity = quantity,
        Search.filter = filter_,
        Search.descriptions = descriptions,
        Search.upTo = upTo,
        Search.destination = destination,
        Search.subject = subject,
        Search.slot = slot,
        Search.differentIn = differentIn,
        Search.exactly = exactly,
        Search.andOr = andOr
      }
