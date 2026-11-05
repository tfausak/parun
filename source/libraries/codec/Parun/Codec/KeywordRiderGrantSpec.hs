module Parun.Codec.KeywordRiderGrantSpec where

import qualified Parun.Codec.KeywordRiderGrant as KeywordRiderGrant
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordDesignator as KeywordDesignator
import qualified Parun.Types.KeywordRiderGrant as KeywordRiderGrant
import qualified Parun.Types.RiderClause as RiderClause

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.KeywordRiderGrant" $ do
  -- Birgi, God of Storytelling's, its filter cut down.
  Spec.it s "a TimesEachTurn grant" $
    Common.assertCodec
      s
      KeywordRiderGrant.codec
      ( KeywordRiderGrant.MkKeywordRiderGrant
          { KeywordRiderGrant.abilities = KeywordDesignator.OfKeyword Keyword.Boast,
            KeywordRiderGrant.relaxes = RiderClause.TimesEachTurn 2,
            KeywordRiderGrant.permanents = Filter.IsSource
          }
      )
      " {\"abilities\":{\"type\":\"OfKeyword\",\"value\":{\"type\":\"Boast\"}},\"relaxes\":{\"type\":\"TimesEachTurn\",\"value\":2},\"permanents\":{\"type\":\"IsSource\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s KeywordRiderGrant.codec
