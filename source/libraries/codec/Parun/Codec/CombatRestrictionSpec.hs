module Parun.Codec.CombatRestrictionSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.CombatRestriction as CombatRestriction
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AffectedUnless as AffectedUnless
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.AloneUnless as AloneUnless
import qualified Parun.Types.AttackLimitUnless as AttackLimitUnless
import qualified Parun.Types.AttackTargetKind as AttackTargetKind
import qualified Parun.Types.CantAttackPlayer as CantAttackPlayer
import qualified Parun.Types.CantBeBlockedBy as CantBeBlockedBy
import qualified Parun.Types.CantBlockCreatures as CantBlockCreatures
import qualified Parun.Types.CombatRestriction as CombatRestriction
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Count as Count
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.LimitUnless as LimitUnless
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.Operand as Operand
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CombatRestriction" $ do
  -- CR 508.1c's first clause: unconditional, so the "unless" key is absent
  -- rather than null.
  Spec.it s "CantAttack carries its Affected" $
    Common.assertCodec
      s
      CombatRestriction.codec
      (CombatRestriction.CantAttack (AffectedUnless.MkAffectedUnless Affected.Attached Nothing Nothing Nothing))
      " {\"type\":\"CantAttack\",\"value\":{\"affected\":{\"type\":\"Attached\"}}} "
  -- CR 509.1b, the blocking counterpart.
  Spec.it s "CantBlock carries its Affected" $
    Common.assertCodec
      s
      CombatRestriction.codec
      (CombatRestriction.CantBlock (AffectedUnless.MkAffectedUnless Affected.Attached Nothing Nothing Nothing))
      " {\"type\":\"CantBlock\",\"value\":{\"affected\":{\"type\":\"Attached\"}}} "
  -- CR 509.1b's attacker-side PAIRWISE arm, whose payload has a second Filter
  -- position: "blockers" beside "affected", never a second "affected", since the
  -- two describe opposite sides of the block.
  Spec.it s "CantBeBlockedBy carries its Affected and its blockers" $
    Common.assertCodec
      s
      CombatRestriction.codec
      (CombatRestriction.CantBeBlockedBy (CantBeBlockedBy.MkCantBeBlockedBy Affected.Attached (Filter.Measures (Measures.MkMeasures Measure.Power Comparison.GreaterThan (Operand.OfSource Measure.Power))) Nothing Nothing))
      " {\"type\":\"CantBeBlockedBy\",\"value\":{\"affected\":{\"type\":\"Attached\"},\"blockers\":{\"type\":\"Measures\",\"value\":{\"measure\":{\"type\":\"Power\"},\"comparison\":{\"type\":\"GreaterThan\"},\"operand\":{\"type\":\"OfSource\",\"value\":{\"type\":\"Power\"}}}}}} "
  -- Its blocker-side mirror: "attackers" beside "affected".
  Spec.it s "CantBlockCreatures carries its Affected and its attackers" $
    Common.assertCodec
      s
      CombatRestriction.codec
      (CombatRestriction.CantBlockCreatures (CantBlockCreatures.MkCantBlockCreatures Affected.Attached (Filter.Measures (Measures.MkMeasures Measure.Power Comparison.GreaterThan (Operand.OfSource Measure.Power))) Nothing Nothing))
      " {\"type\":\"CantBlockCreatures\",\"value\":{\"affected\":{\"type\":\"Attached\"},\"attackers\":{\"type\":\"Measures\",\"value\":{\"measure\":{\"type\":\"Power\"},\"comparison\":{\"type\":\"GreaterThan\"},\"operand\":{\"type\":\"OfSource\",\"value\":{\"type\":\"Power\"}}}}}} "
  -- CR 508.1c's PAIRWISE arm, the attacking one, whose payload spells
  -- "defenders" where CantBeBlockedBy spells "blockers": the players the
  -- restricted creatures may not be announced against (CR 508.1b), together
  -- with which of CR 506.3's things on that player's side (the "kinds").
  Spec.it s "CantAttackPlayer carries its Affected, its defenders and its kinds" $
    Common.assertCodec
      s
      CombatRestriction.codec
      (CombatRestriction.CantAttackPlayer (CantAttackPlayer.MkCantAttackPlayer Affected.Attached (PlayerScope.Related PlayerRelation.You) (Set.singleton AttackTargetKind.OfPlaneswalker) Nothing Nothing))
      " {\"type\":\"CantAttackPlayer\",\"value\":{\"affected\":{\"type\":\"Attached\"},\"defenders\":{\"type\":\"You\"},\"kinds\":[{\"type\":\"OfPlaneswalker\"}]}} "
  -- CR 508.1c together with CR 506.5, the SET-SHAPED arm: the same payload as
  -- the two above, so the tag is the only thing that tells a reader this one is
  -- answered against a whole declaration.
  Spec.it s "CantAttackAlone carries its Affected" $
    Common.assertCodec
      s
      CombatRestriction.codec
      (CombatRestriction.CantAttackAlone (AloneUnless.MkAloneUnless Affected.Attached Nothing Nothing Nothing))
      " {\"type\":\"CantAttackAlone\",\"value\":{\"affected\":{\"type\":\"Attached\"}}} "
  -- CR 509.1b's twin of the arm above. A different Affected, so a codec that
  -- crossed the two arms cannot pass both.
  Spec.it s "CantBlockAlone carries its Affected" $
    Common.assertCodec
      s
      CombatRestriction.codec
      (CombatRestriction.CantBlockAlone (AloneUnless.MkAloneUnless (Affected.Matching Filter.IsSource) Nothing Nothing Nothing))
      " {\"type\":\"CantBlockAlone\",\"value\":{\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}}}} "
  -- The SIZE-BOUNDING arms, whose payload spells "limit" where the three above
  -- spell "affected". They are here as much for the DECODER as for the shape:
  -- Parun.Codec.CombatRestriction.fromJson dispatches on a string, so an arm
  -- missing there compiles and fails only when a card file is loaded, and these
  -- two cases are what turn that into a test failure.
  Spec.it s "CantAttackMoreThan carries its limit" $
    Common.assertCodec
      s
      CombatRestriction.codec
      (CombatRestriction.CantAttackMoreThan (AttackLimitUnless.MkAttackLimitUnless 1 Nothing Nothing))
      " {\"type\":\"CantAttackMoreThan\",\"value\":{\"limit\":1}} "
  -- CR 509.1b, the blocking counterpart. A DIFFERENT limit from the one above,
  -- so a codec that crossed the two arms' payloads cannot pass both.
  Spec.it s "CantBlockMoreThan carries its limit" $
    Common.assertCodec
      s
      CombatRestriction.codec
      (CombatRestriction.CantBlockMoreThan (LimitUnless.MkLimitUnless 2 Comparison.AtMost Nothing Nothing))
      " {\"type\":\"CantBlockMoreThan\",\"value\":{\"limit\":2}} "
  -- CR 802.3a: the attacking bound SCOPED to a seat, which is the one key the
  -- two payloads above do not share. Crawlspace writes it; Silent Arbiter's
  -- case above is the unscoped control beside it.
  Spec.it s "CantAttackMoreThan carries its defenders" $
    Common.assertCodec
      s
      CombatRestriction.codec
      (CombatRestriction.CantAttackMoreThan (AttackLimitUnless.MkAttackLimitUnless 3 (Just (PlayerScope.Related PlayerRelation.You)) Nothing))
      " {\"type\":\"CantAttackMoreThan\",\"value\":{\"limit\":3,\"defenders\":{\"type\":\"You\"}}} "
  -- CR 508.1c's second clause: the gated form.
  Spec.it s "CantAttack carries its condition" $
    Common.assertCodec
      s
      CombatRestriction.codec
      (CombatRestriction.CantAttack (AffectedUnless.MkAffectedUnless Affected.Attached (Just anotherGiant) Nothing Nothing))
      ( "{\"type\":\"CantAttack\",\"value\":{\"affected\":{\"type\":\"Attached\"},\"unless\":"
          <> "{\"type\":\"Compares\",\"value\":"
          <> "{\"measured\":{\"type\":\"Count\",\"value\":{\"scope\":{\"type\":\"InZone\",\"value\":{\"zone\":{\"type\":\"Battlefield\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}}}},"
          <> "\"filter\":{\"type\":\"And\",\"value\":[{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Giant\"}},{\"type\":\"ControlledBy\",\"value\":{\"type\":\"You\"}}]},"
          <> "\"aggregation\":{\"type\":\"Members\"}}},"
          <> "\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":1}}}}}"
      )
  -- CR 509.1b's second clause is the same sentence with "block" in place of
  -- "attack", so the gate rides the other arm unchanged.
  Spec.it s "CantBlock carries its condition" $
    Spec.assertEqWith
      s
      "preserved"
      (Codec.decode CombatRestriction.codec (Codec.encode CombatRestriction.codec (CombatRestriction.CantBlock (AffectedUnless.MkAffectedUnless Affected.Attached (Just anotherGiant) Nothing Nothing))))
      (Right (CombatRestriction.CantBlock (AffectedUnless.MkAffectedUnless Affected.Attached (Just anotherGiant) Nothing Nothing)))
  Spec.it s "has a schema" $ Common.assertHasSchema s CombatRestriction.codec

-- "you control a Giant", without the `Not IsSource` conjunct that would make it
-- "another Giant" -- dropped only to keep the expected string readable, since
-- Parun.Codec.FilterSpec covers that conjunct.

anotherGiant :: Condition.Condition
anotherGiant =
  Condition.Compares
    ( Compares.MkCompares
        ( Quantity.Count
            ( Count.MkCount
                (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer)))
                (Filter.And [Filter.HasSubtype Subtype.Giant, Filter.ControlledBy PlayerRelation.You])
                Aggregation.Members
            )
        )
        Comparison.AtLeast
        (Quantity.Literal 1)
    )
