{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ChooseCardName where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ChooseCardName as ChooseCardName

-- | @player@ and @restriction@ are REQUIRED; @among@ is elided rather than
-- written null. The chooser has no default worth writing: CR 109.5's "you" is a
-- reading of the printed words rather than an absence, so a card that means it
-- says so, exactly as Parun.Codec.Search's two PlayerRefs do.
codec :: Codec.Codec ChooseCardName.ChooseCardName
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec ChooseCardName.player
  restriction <- Fields.required "restriction" (Filter.codec Keyword.codec) ChooseCardName.restriction
  among <- Fields.defaulted "among" Nothing (Common.maybe SlotName.codec) ChooseCardName.among
  pure
    ChooseCardName.MkChooseCardName
      { ChooseCardName.player = player,
        ChooseCardName.restriction = restriction,
        ChooseCardName.among = among
      }
