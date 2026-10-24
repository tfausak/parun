{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.FullText where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.FullText as FullText

codec :: (Typeable.Typeable ability) => Codec.Codec ability -> Codec.Codec (FullText.FullText ability)
codec abilityCodec = Fields.object $ do
  graveyard <- Fields.required "graveyard" PlayerRef.codec FullText.graveyard
  alsoHas <- Fields.required "alsoHas" (Common.list abilityCodec) FullText.alsoHas
  pure FullText.MkFullText {FullText.graveyard = graveyard, FullText.alsoHas = alsoHas}
