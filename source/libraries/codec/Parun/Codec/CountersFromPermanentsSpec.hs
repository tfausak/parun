module Parun.Codec.CountersFromPermanentsSpec where

import qualified Data.Either as Either
import qualified Data.Text as Text
import qualified Parun.Codec.CountersFromPermanents as CountersFromPermanents
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterSpread as CounterSpread
import qualified Parun.Types.CountersFromPermanents as CountersFromPermanents
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.WhichCounters as WhichCounters

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (CountersFromPermanents.CountersFromPermanents Keyword.Keyword)
codec = CountersFromPermanents.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CountersFromPermanents" $ do
  -- Zameck Guildmage's one counter. The count is COUNTERS, and the key name is
  -- SINGULAR -- where TapPermanents' `whichPermanents` narrows a set of objects,
  -- this narrows the one permanent they come off.
  Spec.it s "MkCountersFromPermanents" $
    Common.assertCodec
      s
      codec
      ( CountersFromPermanents.MkCountersFromPermanents
          { CountersFromPermanents.count = CostAmount.Fixed 1,
            CountersFromPermanents.kind = WhichCounters.OfKind CounterKind.PlusOnePlusOne,
            CountersFromPermanents.whichPermanent = Filter.HasCardType CardType.Creature,
            CountersFromPermanents.spread = CounterSpread.FromOne
          }
      )
      " {\"count\":{\"type\":\"Fixed\",\"value\":1},\"kind\":{\"type\":\"OfKind\",\"value\":{\"type\":\"PlusOnePlusOne\"}},\"whichPermanent\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- Tayam, Luminous Enigma's three counters of any kind, divided among
  -- creatures: the spread is written only where it is not the one-permanent
  -- default.
  Spec.it s "FromAmong" $
    Common.assertCodec
      s
      codec
      ( CountersFromPermanents.MkCountersFromPermanents
          { CountersFromPermanents.count = CostAmount.Fixed 3,
            CountersFromPermanents.kind = WhichCounters.OfAnyKind,
            CountersFromPermanents.whichPermanent = Filter.HasCardType CardType.Creature,
            CountersFromPermanents.spread = CounterSpread.FromAmong
          }
      )
      " {\"count\":{\"type\":\"Fixed\",\"value\":3},\"kind\":{\"type\":\"OfAnyKind\"},\"whichPermanent\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"spread\":{\"type\":\"FromAmong\"}} "
  Spec.it s "rejects counters of any kind at a floor" $
    Spec.assertBool
      s
      (Either.isLeft (Codec.decode codec =<< Common.parse (Text.pack "{\"count\":{\"type\":\"Fixed\",\"value\":1},\"kind\":{\"type\":\"OfAnyKind\"},\"whichPermanent\":{\"type\":\"IsSource\"},\"spread\":{\"type\":\"FromAmongAtLeast\"}}")))
      "expected a decode failure"
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
