module Parun.Codec.CantBeBlockedBySpec where

import qualified Parun.Codec.CantBeBlockedBy as CantBeBlockedBy
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.CantBeBlockedBy as CantBeBlockedBy
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.Operand as Operand

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CantBeBlockedBy" $ do
  -- CR 509.1b's pairwise restriction. Both creature-naming keys carry a Filter,
  -- so the fixture makes them differ on purpose: only an asymmetric case catches
  -- a codec that barred the attackers from themselves.
  Spec.it s "MkCantBeBlockedBy, unless elided" $
    Common.assertCodec
      s
      CantBeBlockedBy.codec
      ( CantBeBlockedBy.MkCantBeBlockedBy
          { CantBeBlockedBy.affected = Affected.Matching (Filter.HasCardType CardType.Creature),
            CantBeBlockedBy.blockers = Filter.Measures (Measures.MkMeasures Measure.Power Comparison.GreaterThan (Operand.OfSource Measure.Power)),
            CantBeBlockedBy.unless = Nothing,
            CantBeBlockedBy.name = Nothing
          }
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"blockers\":{\"type\":\"Measures\",\"value\":{\"measure\":{\"type\":\"Power\"},\"comparison\":{\"type\":\"GreaterThan\"},\"operand\":{\"type\":\"OfSource\",\"value\":{\"type\":\"Power\"}}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CantBeBlockedBy.codec
