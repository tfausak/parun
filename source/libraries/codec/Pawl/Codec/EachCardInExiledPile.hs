{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.EachCardInExiledPile where

import qualified Pawl.Codec.ExiledPile as ExiledPile
import qualified Pawl.Codec.Filter as Filter
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.EachCardInExiledPile as EachCardInExiledPile

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Pawl.Codec.ObjectRef's EachCardInExiledPile arm. @pile@ is
-- required, so a payload in an older spelling fails to decode rather than
-- naming a default pile; @filter@ is omitted when absent.
codec :: Codec.Codec EachCardInExiledPile.EachCardInExiledPile
codec = Fields.object $ do
  pile <- Fields.required "pile" ExiledPile.codec EachCardInExiledPile.pile
  filter_ <- Fields.defaulted "filter" Nothing (Common.maybe (Filter.codec Keyword.codec)) EachCardInExiledPile.filter
  pure
    EachCardInExiledPile.MkEachCardInExiledPile
      { EachCardInExiledPile.pile = pile,
        EachCardInExiledPile.filter = filter_
      }
