{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Cost where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.CostComponent as CostComponent
import qualified Parun.Codec.ManaCost as ManaCost
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Cost as Cost

-- | The keyword codec is a PARAMETER; see Parun.Codec.Filter's header. The 'Eq'
-- constraint is only for 'Fields.defaulted' on 'components', the same reason
-- the pre-'Codec' version needed it for 'Common.optionalPair'.
--
-- CR 118.6: 'mana' is REQUIRED, not defaulted, despite being a 'Maybe' --
-- Nothing and Just (MkManaCost []) are both real, distinct values, so there is
-- no single default an absent key could mean. A card file that forgets 'mana'
-- is malformed rather than unpayable-by-default.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Cost.Cost keyword)
codec keywordCodec = Fields.object $ do
  mana <- Fields.required "mana" (Common.maybe ManaCost.codec) Cost.mana
  components <- Fields.defaulted "components" [] (Common.list (CostComponent.codec keywordCodec)) Cost.components
  pure Cost.MkCost {Cost.mana = mana, Cost.components = components}
