{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BlockCost where

import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PerCreature as PerCreature
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BlockCost as BlockCost

-- | "subject" is Parun.Codec.AttackCost's key and names the same axis: the
-- creatures the effect is ABOUT. "perBlocker" is one blocker's share, not the
-- card's whole cost -- a "for each" would repeat it per taxed blocker before CR
-- 509.1d totals the declaration.
--
-- No "scope" key, which is where this codec is not its twin's mirror:
-- Parun.Types.BlockCost's header says why. "attackers" is absent for a cost on
-- every block.
codec :: Codec.Codec BlockCost.BlockCost
codec = Fields.object $ do
  subject <- Fields.required "subject" Affected.codec BlockCost.subject
  perBlocker <- Fields.required "perBlocker" PerCreature.codec BlockCost.perBlocker
  attackers <- Fields.defaulted "attackers" Nothing (Common.maybe (Filter.codec Keyword.codec)) BlockCost.attackers
  pure
    BlockCost.MkBlockCost
      { BlockCost.subject = subject,
        BlockCost.perBlocker = perBlocker,
        BlockCost.attackers = attackers
      }
