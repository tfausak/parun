module Parun.Codec.EntriesTriggerSpec where

import qualified Parun.Codec.EntriesTrigger as EntriesTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.EntriesTrigger as EntriesTrigger
import qualified Parun.Types.EntryTriggering as EntryTriggering
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EntriesTrigger" $ do
  -- Torpor Orb's "creatures entering don't cause abilities to trigger".
  Spec.it s "MkEntriesTrigger" $
    Common.assertCodec
      s
      EntriesTrigger.codec
      ( EntriesTrigger.MkEntriesTrigger
          { EntriesTrigger.entrants = Filter.HasCardType CardType.Creature,
            EntriesTrigger.triggering = EntryTriggering.NoTrigger
          }
      )
      " {\"entrants\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"triggering\":{\"type\":\"NoTrigger\"}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s EntriesTrigger.codec
