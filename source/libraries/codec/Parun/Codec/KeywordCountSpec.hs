module Parun.Codec.KeywordCountSpec where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.KeywordCount as KeywordCount
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordCount as KeywordCount
import qualified Parun.Types.KeywordTally as KeywordTally
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Types.PlayerCounterTally as PlayerCounterTally
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.Zone as Zone

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (KeywordCount.KeywordCount Keyword.Keyword)
codec = KeywordCount.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.KeywordCount" $ do
  -- CR 702.181a: Dalkovan Packbeasts' mobilize 3.
  Spec.it s "Fixed carries its N" $
    Common.assertCodec s codec (KeywordCount.Fixed 3) " {\"type\":\"Fixed\",\"value\":3} "
  -- Firebending Student's "firebending X, where X is this creature's power".
  Spec.it s "Power carries none" $
    Common.assertCodec s codec KeywordCount.Power " {\"type\":\"Power\"} "
  -- Avenger of the Fallen's "the number of creature cards in your graveyard".
  Spec.it s "Tally carries a scope and a filter" $
    Common.assertCodec
      s
      codec
      ( KeywordCount.Tally
          KeywordTally.MkKeywordTally
            { KeywordTally.scope = Scope.InZone InZone.MkInZone {InZone.zone = Zone.Graveyard, InZone.player = PlayerRef.Relative PlayerRelation.You},
              KeywordTally.filter = Filter.HasCardType CardType.Creature
            }
      )
      " {\"type\":\"Tally\",\"value\":{\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"scope\":{\"type\":\"InZone\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"zone\":{\"type\":\"Graveyard\"}}}}} "
  -- Zuko, Firebending Master's "the number of experience counters you have".
  Spec.it s "PlayerCounters carries a player and a kind" $
    Common.assertCodec
      s
      codec
      (KeywordCount.PlayerCounters PlayerCounterTally.MkPlayerCounterTally {PlayerCounterTally.player = PlayerRef.Relative PlayerRelation.You, PlayerCounterTally.kind = PlayerCounterKind.Experience})
      " {\"type\":\"PlayerCounters\",\"value\":{\"kind\":{\"type\":\"Experience\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
