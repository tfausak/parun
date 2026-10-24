{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ChooseCardName where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ChooseCardName as ChooseCardName

-- | Both fields are REQUIRED. The chooser has no default worth writing: CR
-- 109.5's "you" is a reading of the printed words rather than an absence, so a
-- card that means it says so, exactly as Parun.Codec.Search's two PlayerRefs do.
codec :: Codec.Codec ChooseCardName.ChooseCardName
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec ChooseCardName.player
  restriction <- Fields.required "restriction" (Filter.codec Keyword.codec) ChooseCardName.restriction
  pure
    ChooseCardName.MkChooseCardName
      { ChooseCardName.player = player,
        ChooseCardName.restriction = restriction
      }
