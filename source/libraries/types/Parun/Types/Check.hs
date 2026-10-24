module Parun.Types.Check where

import qualified Parun.Types.AttackersAre as AttackersAre
import qualified Parun.Types.BlockersAre as BlockersAre
import qualified Parun.Types.CountIs as CountIs
import qualified Parun.Types.CountersAre as CountersAre
import qualified Parun.Types.DamageIs as DamageIs
import qualified Parun.Types.DefendersAre as DefendersAre
import qualified Parun.Types.KeywordsAre as KeywordsAre
import qualified Parun.Types.LifeIs as LifeIs
import qualified Parun.Types.MonarchIs as MonarchIs
import qualified Parun.Types.NamesAre as NamesAre
import qualified Parun.Types.PlayerCountersAre as PlayerCountersAre
import qualified Parun.Types.PowerToughnessIs as PowerToughnessIs
import qualified Parun.Types.SubtypesAre as SubtypesAre
import qualified Parun.Types.TappedIs as TappedIs
import qualified Parun.Types.TypesAre as TypesAre
import qualified Parun.Types.ViewIs as ViewIs

-- | One fact a scenario asserts about the game, in the nouns a client would
-- display.
data Check
  = Life LifeIs.LifeIs
  | Count CountIs.CountIs
  | Damage DamageIs.DamageIs
  | Tapped TappedIs.TappedIs
  | Counters CountersAre.CountersAre
  | Types TypesAre.TypesAre
  | Attackers AttackersAre.AttackersAre
  | Blockers BlockersAre.BlockersAre
  | Defenders DefendersAre.DefendersAre
  | Monarch MonarchIs.MonarchIs
  | PowerToughness PowerToughnessIs.PowerToughnessIs
  | PlayerCounters PlayerCountersAre.PlayerCountersAre
  | Subtypes SubtypesAre.SubtypesAre
  | Names NamesAre.NamesAre
  | View ViewIs.ViewIs
  | Keywords KeywordsAre.KeywordsAre
  deriving (Eq, Ord, Show)
