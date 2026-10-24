module Parun.Codec.Check where

import qualified Parun.Codec.AttackersAre as AttackersAre
import qualified Parun.Codec.BlockersAre as BlockersAre
import qualified Parun.Codec.CountIs as CountIs
import qualified Parun.Codec.CountersAre as CountersAre
import qualified Parun.Codec.DamageIs as DamageIs
import qualified Parun.Codec.DefendersAre as DefendersAre
import qualified Parun.Codec.KeywordsAre as KeywordsAre
import qualified Parun.Codec.LifeIs as LifeIs
import qualified Parun.Codec.MonarchIs as MonarchIs
import qualified Parun.Codec.NamesAre as NamesAre
import qualified Parun.Codec.PlayerCountersAre as PlayerCountersAre
import qualified Parun.Codec.PowerToughnessIs as PowerToughnessIs
import qualified Parun.Codec.SubtypesAre as SubtypesAre
import qualified Parun.Codec.TappedIs as TappedIs
import qualified Parun.Codec.TypesAre as TypesAre
import qualified Parun.Codec.ViewIs as ViewIs
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Check as Check

-- | Keyed, as Parun.Codec.Move is: @{"Life": {"player": "bob", "life": 18}}@.
codec :: Codec.Codec Check.Check
codec =
  Arm.keyed
    tagOf
    [ Arm.payload "Life" LifeIs.codec Check.Life (\x -> case x of Check.Life y -> Just y; _ -> Nothing),
      Arm.payload "Count" CountIs.codec Check.Count (\x -> case x of Check.Count y -> Just y; _ -> Nothing),
      Arm.payload "Damage" DamageIs.codec Check.Damage (\x -> case x of Check.Damage y -> Just y; _ -> Nothing),
      Arm.payload "Tapped" TappedIs.codec Check.Tapped (\x -> case x of Check.Tapped y -> Just y; _ -> Nothing),
      Arm.payload "Counters" CountersAre.codec Check.Counters (\x -> case x of Check.Counters y -> Just y; _ -> Nothing),
      Arm.payload "Types" TypesAre.codec Check.Types (\x -> case x of Check.Types y -> Just y; _ -> Nothing),
      Arm.payload "Attackers" AttackersAre.codec Check.Attackers (\x -> case x of Check.Attackers y -> Just y; _ -> Nothing),
      Arm.payload "Blockers" BlockersAre.codec Check.Blockers (\x -> case x of Check.Blockers y -> Just y; _ -> Nothing),
      Arm.payload "Defenders" DefendersAre.codec Check.Defenders (\x -> case x of Check.Defenders y -> Just y; _ -> Nothing),
      Arm.payload "Monarch" MonarchIs.codec Check.Monarch (\x -> case x of Check.Monarch y -> Just y; _ -> Nothing),
      Arm.payload "PowerToughness" PowerToughnessIs.codec Check.PowerToughness (\x -> case x of Check.PowerToughness y -> Just y; _ -> Nothing),
      Arm.payload "PlayerCounters" PlayerCountersAre.codec Check.PlayerCounters (\x -> case x of Check.PlayerCounters y -> Just y; _ -> Nothing),
      Arm.payload "Subtypes" SubtypesAre.codec Check.Subtypes (\x -> case x of Check.Subtypes y -> Just y; _ -> Nothing),
      Arm.payload "Names" NamesAre.codec Check.Names (\x -> case x of Check.Names y -> Just y; _ -> Nothing),
      Arm.payload "View" ViewIs.codec Check.View (\x -> case x of Check.View y -> Just y; _ -> Nothing),
      Arm.payload "Keywords" KeywordsAre.codec Check.Keywords (\x -> case x of Check.Keywords y -> Just y; _ -> Nothing)
    ]

tagOf :: Check.Check -> String
tagOf x = case x of
  Check.Life {} -> "Life"
  Check.Count {} -> "Count"
  Check.Damage {} -> "Damage"
  Check.Tapped {} -> "Tapped"
  Check.Counters {} -> "Counters"
  Check.Types {} -> "Types"
  Check.Attackers {} -> "Attackers"
  Check.Blockers {} -> "Blockers"
  Check.Defenders {} -> "Defenders"
  Check.Monarch {} -> "Monarch"
  Check.PowerToughness {} -> "PowerToughness"
  Check.PlayerCounters {} -> "PlayerCounters"
  Check.Subtypes {} -> "Subtypes"
  Check.Names {} -> "Names"
  Check.View {} -> "View"
  Check.Keywords {} -> "Keywords"
