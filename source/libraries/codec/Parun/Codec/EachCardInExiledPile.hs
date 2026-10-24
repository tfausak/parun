{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.EachCardInExiledPile where

import qualified Parun.Codec.ExiledPile as ExiledPile
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EachCardInExiledPile as EachCardInExiledPile

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.ObjectRef's EachCardInExiledPile arm. @pile@ is
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
