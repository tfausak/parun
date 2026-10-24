module Parun.Codec.EntryRestrictionSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.EntryRestriction as EntryRestriction
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.EntryRestriction as EntryRestriction
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EntryRestriction" $ do
  -- Grafdigger's Cage's first sentence (CR 400.4a / CR 101.2), spelled exactly as
  -- data/cards/grafdiggers-cage.json spells it: the two origin zones are what
  -- keep the prohibition off a creature spell on the STACK, so this round-trips
  -- them in the position the card actually writes them.
  Spec.it s "MkEntryRestriction" $
    Common.assertCodec
      s
      EntryRestriction.codec
      ( EntryRestriction.MkEntryRestriction
          (Affected.MatchingOffBattlefield (Filter.HasCardType CardType.Creature))
          (Set.fromList [Zone.Library, Zone.Graveyard])
      )
      " {\"affected\":{\"type\":\"MatchingOffBattlefield\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"origins\":[{\"type\":\"Library\"},{\"type\":\"Graveyard\"}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s EntryRestriction.codec
