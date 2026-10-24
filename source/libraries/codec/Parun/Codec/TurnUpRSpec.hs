module Parun.Codec.TurnUpRSpec where

import qualified Parun.Codec.TurnUpR as TurnUpR
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.TurnUpProcedure as TurnUpProcedure
import qualified Parun.Types.TurnUpR as TurnUpR
import qualified Parun.Types.TurnUpRewrite as TurnUpRewrite
import qualified Parun.Types.WithCounters as WithCounters

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TurnUpR" $ do
  -- Bubble Smuggler's clause, the shape a CARD writes: no `requiring`, so the row
  -- applies down every road CR 614.1e reaches, and the field stays off the wire.
  Spec.it s "MkTurnUpR" $
    Common.assertCodec
      s
      (TurnUpR.codec Common.text Common.text)
      ( TurnUpR.MkTurnUpR
          { TurnUpR.matching = Filter.IsSource,
            TurnUpR.requiring = Nothing,
            TurnUpR.paying = Nothing,
            TurnUpR.rewrite =
              TurnUpRewrite.WithCounters
                (WithCounters.one CounterKind.PlusOnePlusOne (Quantity.Literal 4))
          }
      )
      " {\"matching\":{\"type\":\"IsSource\"},\"rewrite\":{\"type\":\"WithCounters\",\"value\":[{\"kind\":{\"type\":\"PlusOnePlusOne\"},\"count\":{\"type\":\"Literal\",\"value\":4}}]}} "
  -- The other shape, which only Parun.Engine.Keyword.mintedReplacementsFor's
  -- megamorph arm builds: CR 702.37b's counter, conditional on CR 702.37e's
  -- procedure having paid the megamorph cost; see #987.
  Spec.it s "megamorph's baked requiring (CR 702.37b)" $
    Common.assertCodec
      s
      (TurnUpR.codec Common.text Common.text)
      ( TurnUpR.MkTurnUpR
          { TurnUpR.matching = Filter.IsSource,
            TurnUpR.requiring = Just TurnUpProcedure.Morph,
            TurnUpR.paying = Just (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 4])) []),
            TurnUpR.rewrite =
              TurnUpRewrite.WithCounters
                (WithCounters.one CounterKind.PlusOnePlusOne (Quantity.Literal 1))
          }
      )
      " {\"matching\":{\"type\":\"IsSource\"},\"requiring\":{\"type\":\"Morph\"},\"paying\":{\"mana\":[{\"type\":\"Generic\",\"value\":4}]},\"rewrite\":{\"type\":\"WithCounters\",\"value\":[{\"kind\":{\"type\":\"PlusOnePlusOne\"},\"count\":{\"type\":\"Literal\",\"value\":1}}]}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (TurnUpR.codec Common.text Common.text)
