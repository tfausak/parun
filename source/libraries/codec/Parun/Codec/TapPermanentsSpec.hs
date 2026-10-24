module Parun.Codec.TapPermanentsSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.TapPermanents as TapPermanents
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TapPermanents as TapPermanents

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (TapPermanents.TapPermanents Keyword.Keyword)
codec = TapPermanents.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TapPermanents" $ do
  -- Springleaf Drum's one creature. The count is HOW MANY, matched exactly --
  -- the key name is where this differs from TapForTotalPower's threshold.
  Spec.it s "MkTapPermanents" $
    Common.assertCodec
      s
      codec
      ( TapPermanents.MkTapPermanents
          { TapPermanents.count = CostAmount.Fixed 1,
            TapPermanents.whichPermanents = Filter.HasCardType CardType.Creature,
            TapPermanents.sharingACreatureType = False
          }
      )
      " {\"count\":{\"type\":\"Fixed\",\"value\":1},\"whichPermanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- Weight of Conscience's pair, which must share a creature type (CR 205.3m).
  Spec.it s "sharingACreatureType" $
    Common.assertCodec
      s
      codec
      ( TapPermanents.MkTapPermanents
          { TapPermanents.count = CostAmount.Fixed 2,
            TapPermanents.whichPermanents = Filter.HasCardType CardType.Creature,
            TapPermanents.sharingACreatureType = True
          }
      )
      " {\"count\":{\"type\":\"Fixed\",\"value\":2},\"whichPermanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"sharingACreatureType\":true} "
  -- Explosive Singularity's "tap any number", announced at CR 601.2b.
  Spec.it s "Announced" $
    Common.assertCodec
      s
      codec
      ( TapPermanents.MkTapPermanents
          { TapPermanents.count = CostAmount.Announced (SlotName.MkSlotName (Text.pack "X")),
            TapPermanents.whichPermanents = Filter.HasCardType CardType.Creature,
            TapPermanents.sharingACreatureType = False
          }
      )
      " {\"count\":{\"type\":\"Announced\",\"value\":\"X\"},\"whichPermanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
