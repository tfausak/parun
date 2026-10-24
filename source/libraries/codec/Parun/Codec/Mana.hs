module Parun.Codec.Mana where

import qualified Parun.Codec.ManaUnit as ManaUnit
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Mana as Mana

-- | A JSON ARRAY of units and not 'Common.multiset': CR 106.4's pool is unspent
-- mana rather than a count per type, and the type's own haddock says the units
-- are not fungible, so two units differing in provenance are two entries rather
-- than a count of two. 'Common.set' is wrong for the same reason -- a pool
-- really can hold two indistinguishable units.
--
-- ORDER is therefore on the wire. That is a faithful round trip of what the
-- field holds, which is a list; nothing reads a pool positionally, so the order
-- carries no meaning beyond being the one written.
codec :: Codec.Codec Mana.Mana
codec = Common.wrapper (Common.list ManaUnit.codec) Mana.MkMana Mana.unwrap
