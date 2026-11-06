-- | CR 701.47, "amass [subtype] N", and CR 701.71, "empower Jace N": the tokens
-- the rules print, and the whole of both keyword actions, which share one shape.
--
-- Parun.Engine.Ring's sibling, and standing on the same ground: rule 701 is a
-- keyword-action rule exactly as rule 702 is a keyword rule, so minting the token
-- from CR 701.47a or 701.71a here is Parun.Engine.Keyword's standing to mint an
-- ability from a Keyword. The closed\/open invariant forbids the rules core casing
-- on an EFFECT's identity, and nothing here does: Parun.Engine.Resolve's
-- Effect.Amass arm calls `amass` and asks nothing about which effect it came from;
-- casing on the AmassKind is casing on the rulebook's keyword action.
module Parun.Engine.Amass where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Keyword as Keyword
import qualified Parun.Engine.Mint as Mint
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Subtype as Subtype
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.Activator as Activator
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AmassKind as AmassKind
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ChangeMode as ChangeMode
import qualified Parun.Types.Color as Color
import qualified Parun.Types.ContinuousEffect as ContinuousEffect
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.CounterCause as CounterCause
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Counterability as Counterability
import qualified Parun.Types.Draw as Draw
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.Face as Face
import Parun.Types.Game (Game)
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Layout as Layout
import qualified Parun.Types.Loyalty as Loyalty
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.Modification as Modification
import Parun.Types.ObjectId (ObjectId)
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Power as Power
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Subtype as Subtype.Type
import qualified Parun.Types.Surveil as Surveil
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.Toughness as Toughness
import qualified Parun.Types.TypeLine as TypeLine

-- | CR 701.47a's token: a 0\/0 black [subtype] Army creature. Minted here rather
-- than carried in card data, on Parun.Engine.Keyword's terms -- its characteristics
-- are printed in the comprehensive rules, not on Relentless Advance.
--
-- CR 111.4 supplies the name, rule 701.47a naming none: the subtypes plus the word
-- "Token", so a Zombie Army token is named "Zombie Army Token" -- the Servo token's
-- shape. The subtype's word comes from Parun.Engine.Subtype.creatureTypeWord, the
-- same list CR 205.3m holds, so a text-changed amass (CR 612.2a) mints a token named
-- for the NEW word -- Parun.Engine.Projection.Rewrite.rewriteEffect has already swapped the
-- subtype by the time this is called. Nothing there means card data wrote a subtype
-- of another family, which no printing does; the name is "Army Token" in that case
-- rather than this being partial.
--
-- Black is a colorIndicator (CR 202.2e), the Servo token's shape with a colour in
-- it. The 0\/0 is exactly what rule 701.47a prints: the counters land before any
-- state-based action is checked (CR 704.3), so an amass of one or more leaves a
-- creature that survives.
armyToken :: Subtype.Type.Subtype -> Card.Card
armyToken subtype =
  Card.MkCard
    { Card.layout = Layout.Normal,
      Card.faces =
        NonEmpty.singleton
          Face.MkFace
            { Face.name =
                CardName.MkCardName
                  ( Text.unwords
                      (Maybe.maybeToList (Subtype.creatureTypeWord subtype) <> [Text.pack "Army", Text.pack "Token"])
                  ),
              Face.oracleText = Nothing,
              Face.manaCost = Nothing,
              Face.typeLine =
                TypeLine.MkTypeLine
                  Set.empty
                  (Set.singleton CardType.Creature)
                  (Set.fromList [subtype, Subtype.Type.Army]),
              Face.power = Just (Power.MkPower (Quantity.Literal 0)),
              Face.toughness = Just (Toughness.MkToughness (Quantity.Literal 0)),
              Face.loyalty = Nothing,
              Face.defense = Nothing,
              Face.startingIntensity = Nothing,
              Face.vanguard = Nothing,
              Face.canBeYourCommander = False,
              Face.claimsStartingPlayer = False,
              Face.anteOnly = False,
              Face.keywords = Map.empty,
              Face.colorIndicator = Set.singleton Color.Black,
              Face.characteristicPT = Nothing,
              Face.staticAbilities = [],
              Face.spell = Face.defaultSpell,
              Face.activatedAbilities = [],
              Face.replacementEffects = [],
              Face.triggeredAbilities = [],
              Face.delayedAbilities = Map.empty,
              Face.rooms = Seq.empty,
              Face.dungeonEntryQuality = Nothing,
              Face.castingPermissions = [],
              Face.castingRestrictions = [],
              Face.enchant = [],
              Face.counterability = Counterability.Counterable,
              Face.additionalCosts = [],
              Face.additionalCostChoices = [],
              Face.modeCosts = Map.empty,
              Face.modeChooser = PlayerRelation.You,
              Face.maximumX = [],
              Face.minimumX = 0,
              Face.alternativeCosts = [],
              Face.costReductions = [],
              Face.playerAbilities = [],
              Face.blockRequirements = [],
              Face.blockPermissions = [],
              Face.attackRequirements = [],
              Face.combatRestrictions = [],
              Face.sacrificeRestrictions = [],
              Face.untapRestrictions = [],
              Face.attachRestrictions = [],
              Face.counterRestrictions = [],
              Face.crewRestrictions = [],
              Face.targetRestrictions = [],
              Face.attackPermissions = [],
              Face.activationProhibitions = [],
              Face.entryRestrictions = [],
              Face.attackCosts = [],
              Face.blockCosts = [],
              Face.mulliganActions = [],
              Face.openingHandActions = [],
              Face.specialActions = []
            }
    }

-- | CR 701.71a's token: a blue Jace planeswalker with 0 loyalty, "[−1]: Surveil
-- 1" and "[−3]: Draw a card". Minted here on armyToken's terms; CR 111.4 names it
-- "Jace Token", and blue is a colorIndicator (CR 202.2e).
--
-- The 0 loyalty is CR 306.5b's printed number, so the token enters with no
-- loyalty counters; empower Jace's own counters land in the same instruction,
-- before CR 704.5i is checked (CR 704.3).
jaceToken :: Card.Card
jaceToken =
  let card =
        Keyword.tokenCard
          (Text.pack "Jace Token")
          (TypeLine.MkTypeLine Set.empty (Set.singleton CardType.Planeswalker) (Set.singleton Subtype.Type.Jace))
          (Set.singleton Color.Blue)
          Nothing
          [ loyaltyAbility 1 (Effect.Surveil (Surveil.MkSurveil you (Quantity.Literal 1) Nothing)),
            loyaltyAbility 3 (Effect.Draw (Draw.MkDraw you (Quantity.Literal 1) Nothing))
          ]
      you = PlayerRef.Relative PlayerRelation.You
   in card {Card.faces = fmap (\face -> face {Face.loyalty = Just (Loyalty.Literal 0)}) (Card.faces card)}

-- CR 606.4's "[−N]:" loyalty ability over one effect, an ability the rule
-- defines the token with (CR 111.3) rather than one a keyword grants.
loyaltyAbility :: Natural -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card) -> ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)
loyaltyAbility n effect =
  ActivatedAbility.MkActivatedAbility
    { ActivatedAbility.cost =
        Cost.MkCost
          { Cost.mana = Just (ManaCost.MkManaCost []),
            Cost.components = [CostComponent.RemoveLoyaltyFromThis (CostAmount.Fixed n)]
          },
      ActivatedAbility.modal = Mint.oneMode (Seq.singleton effect),
      ActivatedAbility.maximumX = [],
      ActivatedAbility.minimumX = 0,
      ActivatedAbility.definedX = Nothing,
      ActivatedAbility.restrictions = [],
      ActivatedAbility.activator = Activator.Related PlayerRelation.You,
      ActivatedAbility.condition = Nothing,
      ActivatedAbility.name = Nothing,
      ActivatedAbility.keyword = Nothing
    }

-- | The token CR 701.47a or 701.71a creates.
tokenOf :: AmassKind.AmassKind -> Card.Card
tokenOf kind = case kind of
  AmassKind.Army subtype -> armyToken subtype
  AmassKind.EmpowerJace -> jaceToken

-- | The counters the keyword action puts on the chosen object.
counterKindOf :: AmassKind.AmassKind -> CounterKind.CounterKind keyword
counterKindOf kind = case kind of
  AmassKind.Army _ -> CounterKind.PlusOnePlusOne
  AmassKind.EmpowerJace -> CounterKind.Loyalty

-- | The pool the choice is made out of: armiesOf, or CR 701.71a's "a Jace
-- planeswalker token you control" -- projected type and subtype (CR 613.1d),
-- and a token (CR 111.1), so a Jace CARD is not a candidate.
candidatesOf :: AmassKind.AmassKind -> PlayerId -> GameState.GameState -> [ObjectId]
candidatesOf kind pid gs = case kind of
  AmassKind.Army _ -> armiesOf pid gs
  AmassKind.EmpowerJace ->
    List.sort
      ( filter
          (\oid -> Projection.isPlaneswalkerOf oid gs && Set.member Subtype.Type.Jace (Projection.subtypesOf oid gs) && Game.isToken oid gs)
          (Projection.controls pid gs)
      )

-- | CR 701.47a's "an Army creature you control": the pool the choice is made out
-- of, ascending so that both the single-candidate shortcut and a transcript are
-- deterministic (Parun.Engine.Ring.tempt's posture).
--
-- BOTH conjuncts are the rule's. Creature-ness and the Army type are the PROJECTED
-- questions (CR 613.1d's layer 4), so an Army that has stopped being a creature is
-- not a candidate and a creature that has been made an Army by something else is.
armiesOf :: PlayerId -> GameState.GameState -> [ObjectId]
armiesOf pid gs =
  List.sort
    ( filter
        (\oid -> Projection.isCreatureOf oid gs && Set.member Subtype.Type.Army (Projection.subtypesOf oid gs))
        (Projection.controls pid gs)
    )

-- | CR 701.47a or 701.71a: a player amasses [subtype] N or empowers Jace N. The
-- whole keyword action, in the order both rules fix -- the token BEFORE the
-- choice, so a player who controlled none is choosing among the one they now do.
--
-- Runs to the end whatever happens in the middle, which is CR 701.47b: a player
-- "amassed" once these actions are complete, "even if some or all of those actions
-- were impossible". Nothing here stops early, and the empty pool is a no-op rather
-- than a failure.
--
-- The four instructions in order:
--
-- 1. The condition is on controlling a CANDIDATE (candidatesOf), not on having
--    performed the action before, so a player whose Army died gets a second token.
-- 2. The choice, via Prompt.ChooseAmass through Game.chooseAmong.
-- 3. The counters, through Event.putCounters -- the single funnel (CR 122.6), so
--    CR 614.1's counter replacements (Hardened Scales, Doubling Season) get their
--    opportunity.
-- 4. Amass only: CR 205.1b's type addition, as an ordinary timestamped layer-4
--    continuous effect with Expiry.Never: rule 701.47a states no duration, so
--    nothing ends it. Skipped when the Army already has the subtype, which is the
--    rule's own "if it isn't a [subtype]" and not an optimisation -- the projected
--    types are what that reads.
--
-- ANSWERS the object chosen, which is CR 701.47c's "the amassed Army" -- the
-- caller binds it under the effect's slot for a later clause of the same
-- resolution to read (Surrounded by Orcs). Nothing is rule 701.47b's impossible
-- choice, the empty pool below, and not a failed amass.
amass :: Game () -> PlayerId -> ObjectId -> ObjectId -> AmassKind.AmassKind -> Natural -> Game (Maybe ObjectId)
amass settle pid source resolving kind n = do
  gs0 <- State.get
  -- First: the token, and only if they control no candidate.
  Monad.when (null (candidatesOf kind pid gs0))
    . Monad.void
    $ Event.createTokens settle pid (tokenOf kind) Nothing 1 TapState.Untapped Map.empty Nothing Set.empty
  gs1 <- State.get
  -- CR 701.47b: an impossible choice is not a failed amass. Neither rule is a
  -- "may".
  picked <- Game.chooseAmong (\decider asked -> Prompt.ChooseAmass decider asked resolving) pid (candidatesOf kind pid gs1)
  case picked of
    Nothing -> pure Nothing
    Just chosen -> do
      Monad.when (n > 0)
        . Monad.void
        $ Event.putCounters (CounterCause.ByEffect pid) chosen (counterKindOf kind) n
      gs2 <- State.get
      case kind of
        AmassKind.EmpowerJace -> pure ()
        AmassKind.Army subtype ->
          Monad.unless (Set.member subtype (Projection.subtypesOf chosen gs2)) $ do
            let (ts, gs3) = Game.freshTimestamp gs2
                effect =
                  ContinuousEffect.MkContinuousEffect
                    { ContinuousEffect.source = source,
                      ContinuousEffect.timestamp = ts,
                      ContinuousEffect.expiry = Expiry.Never,
                      ContinuousEffect.modification = Modification.CreatureSubtype ChangeMode.InAddition subtype,
                      ContinuousEffect.affected = Affected.TheseObjects (Set.singleton chosen)
                    }
            State.put gs3 {GameState.continuousEffects = effect : GameState.continuousEffects gs3}
      pure (Just chosen)
