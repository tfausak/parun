-- applyOneEffect's arms from dealDamage to exchangeBlocks, one function per
-- Effect constructor, cut from Parun.Engine.Resolve.Effect along its order so the
-- arms compile in parallel. Each takes the recursion of Parun.Engine.Resolve.Effect
-- it calls back into, then the resolution parameters its body reads, then the
-- constructor's fields.
module Parun.Engine.Resolve.Arms.Damage where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Containers.ListUtils as ListUtils
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import Data.Set (Set)
import qualified Data.Set as Set
import Numeric.Natural (Natural)
import qualified Parun.Engine.Attach as Attach
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Cast as Cast
import qualified Parun.Engine.Coin as Coin
import qualified Parun.Engine.Combat as Combat
import qualified Parun.Engine.Cost as Cost
import qualified Parun.Engine.Damage as Damage
import qualified Parun.Engine.Decide as Decide
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Expiry as Expiry
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Mana as Mana
import qualified Parun.Engine.Plane as Plane
import qualified Parun.Engine.PlayerEffect as PlayerEffect
import qualified Parun.Engine.Players as Players
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Engine.Quantity as Quantity
import qualified Parun.Engine.Replacement as Replacement
import qualified Parun.Engine.Resolve.Common as Common
import Parun.Engine.Resolve.Slots (battlefieldMatching, chosenCandidates, effectContext, effectContextNaming, effectViewOf, legalMany, legalOne, objectRefObjects, playerRefPlayers, resolvingAbilityName, slotBindings)
import qualified Parun.Engine.Restamp as Restamp
import qualified Parun.Engine.Sector as Sector
import qualified Parun.Engine.Setup as Setup
import qualified Parun.Engine.TextWord as TextWord
import qualified Parun.Extra.Integer as Integer
import qualified Parun.Extra.Natural as Natural
import qualified Parun.Types.ActivateManaAbilities as ActivateManaAbilities
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AnyNumberOf as AnyNumberOf
import qualified Parun.Types.Card as Card.Type
import qualified Parun.Types.CarryOver as CarryOver
import qualified Parun.Types.ChangeText as ChangeText
import qualified Parun.Types.ChangeWord as ChangeWord
import qualified Parun.Types.ChoosePermanents as ChoosePermanents
import qualified Parun.Types.ChoosePlayer as ChoosePlayer
import qualified Parun.Types.ChoosePlayerAtRandom as ChoosePlayerAtRandom
import qualified Parun.Types.CoinFace as CoinFace
import qualified Parun.Types.CoinReading as CoinReading
import qualified Parun.Types.ContinuousEffect as ContinuousEffect
import qualified Parun.Types.ControlDuration as ControlDuration
import qualified Parun.Types.ControlPlayer as ControlPlayer
import qualified Parun.Types.DamageEvent as DamageEvent
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamagePart as DamagePart
import qualified Parun.Types.DealDamage as DealDamage
import qualified Parun.Types.Decider as Decider
import qualified Parun.Types.Destroy as Destroy
import qualified Parun.Types.DiceReading as DiceReading
import qualified Parun.Types.ExchangeBlocks as ExchangeBlocks
import qualified Parun.Types.FaceDownReason as FaceDownReason
import qualified Parun.Types.FaceDownState as FaceDownState
import qualified Parun.Types.Facing as Facing
import qualified Parun.Types.Fight as Fight
import qualified Parun.Types.FlipCoin as FlipCoin
import Parun.Types.Game (Game)
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.HandActionPerformer as HandActionPerformer
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.Mana as Mana.Type
import qualified Parun.Types.ManaAbilityPerformer as ManaAbilityPerformer
import qualified Parun.Types.ManaAdded as ManaAdded
import qualified Parun.Types.ManaAddedCause as ManaAddedCause
import qualified Parun.Types.ManaAddition as ManaAddition
import qualified Parun.Types.ManaUnit as ManaUnit
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ModifyTarget as ModifyTarget
import qualified Parun.Types.MoveMana as MoveMana
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import Parun.Types.ObjectRef (ObjectRef)
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.OutsideDestination as OutsideDestination
import qualified Parun.Types.PermanentActed as PermanentActed
import qualified Parun.Types.PermanentAction as PermanentAction
import qualified Parun.Types.PlayerControl as PlayerControl
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.Prompt as Prompt
import Parun.Types.Recipient (Recipient)
import qualified Parun.Types.Recipient as Recipient
import Parun.Types.Result (Result)
import qualified Parun.Types.Result as Result
import qualified Parun.Types.RollDie as RollDie
import qualified Parun.Types.SacrificeEffect as SacrificeEffect
import qualified Parun.Types.Search as Search
import qualified Parun.Types.SearchPlace as SearchPlace
import Parun.Types.SlotName (SlotName)
import qualified Parun.Types.StoredResult as StoredResult
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.Teams as Teams
import qualified Parun.Types.Throw as Throw
import qualified Parun.Types.TurnFaceDown as TurnFaceDown
import qualified Parun.Types.Zone as Zone

dealDamage :: (Game Result -> Game ()) -> (Game Result -> Game ()) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> DealDamage.DealDamage -> Game ()
dealDamage runPreventionRiders runReplacementEffects runSubgame resolving source controller legal (DealDamage.MkDealDamage parts dealer excess mTally mDamaged) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- CR 120.1a: damage only to a battle, creature, or planeswalker, so every
      -- object an ObjectRef names goes through Damage.damageRecipient and none
      -- is trusted. A player recipient survives untouched (CR 115.4, CR 120.3a).
      recipientsOf ref = Maybe.mapMaybe (Damage.damageRecipient gs) (Common.objectRefRecipients legal resolving controller source gs ref)
      -- WHO DEALS IT (CR 120.1): `source` is CR 113.7's default, and a `dealer`
      -- slot is CR 120.2b's exception. Resolved here and carried on the
      -- DamageEvent, so every later reader of "what dealt this" sees the
      -- redirected source. CR 608.2b applies to a dealer as to a recipient: a
      -- dealer whose target went illegal names no object and nothing is dealt.
      dealerId = case dealer of
        Nothing -> Just source
        Just slot -> Maybe.listToMaybe (objectRefObjects legal resolving controller source gs (ObjectRef.InSlot slot))
  dealtEvents <- case dealerId of
    -- No source, no damage: CR 608.2b's illegal dealer, above.
    Nothing -> pure []
    Just dealt -> do
      -- HOW MUCH, read ONCE PER RECIPIENT off the clause that named it: Acidic
      -- Soil's "damage to each player equal to the number of lands they
      -- control" is one amount per seat, and Char's "4 damage to any target and
      -- 2 damage to you" is one amount per clause. Still one action under CR
      -- 608.2f, since every read is against the same pre-effect state. Both
      -- kinds of recipient get it, keyed to recipientSeat. An unevaluable
      -- amount drops that recipient, and so does a zero (CR 120.8).
      --
      -- CR 601.2d's division is read the same way, each recipient handed its
      -- own part (Quantity.Share). A target CR 608.2b found illegal is never
      -- reached, so its part is dealt to nobody rather than reassigned:
      -- data/scenarios/divide's Forked Lightning case proves it.
      let amountFor quantity recipient =
            let sharing = context {Filter.shares = Binding.sharesOf recipient (slotBindings resolving gs)}
             in case Common.recipientSeat gs recipient of
                  Nothing -> Quantity.evaluateFor viewOf sharing gs resolving source quantity
                  Just pid -> Common.evaluateForRecipient viewOf sharing gs resolving source pid quantity
          -- ONE event list from EVERY clause the instruction names, so a
          -- sentence naming objects and players at once -- Molten Disaster's
          -- "each creature without flying and each player" -- reaches
          -- applyDamage as a single CR 608.2f batch rather than one per clause.
          --
          -- And one EVENT per recipient within that batch (CR 120.4), which is
          -- Replacement.oneEventPerRecipient's business: two clauses can name the
          -- same recipient -- Char aimed at its own caster -- and one source
          -- dealing damage to one recipient at one moment deals one event.
          aimed =
            concatMap
              ( \part ->
                  Maybe.mapMaybe
                    ( \recipient -> do
                        n <- amountFor (DamagePart.quantity part) recipient
                        Monad.guard (n > 0)
                        pure (Event.damageEvent gs DamageKind.Noncombat dealt recipient (Integer.toNaturalSaturating n))
                    )
                    (recipientsOf (DamagePart.ref part))
              )
              parts
          events = Replacement.oneEventPerRecipient aimed
          -- CR 120.4a, and BEFORE applyDamage's CR 120.4b, against the same
          -- pre-effect state every amount was read against.
          rewritten = Damage.redirectExcess gs excess events
      if null rewritten
        then pure []
        else do
          -- ONE batch, not one call per recipient: CR 608.2f's "each such
          -- action is processed simultaneously".
          settled <- Damage.applyDamage rewritten
          -- CR 614.1a: what a run-effects rewrite put in a replaced event's
          -- place runs inside this resolution too, and before the riders below.
          runReplacementEffects runSubgame
          -- CR 615.5's "immediately afterward": a shield this damage spent runs
          -- its additional effect inside this resolution.
          runPreventionRiders runSubgame
          pure settled
  -- Syphon Soul's "the damage dealt this way": the SETTLED total, after CR
  -- 615's prevention had its say, so a shielded player contributes only what
  -- got through. Bound even at 0, LoseLife's tally's posture.
  Monad.forM_ mTally $ \slot -> State.modify' (Common.bindAmountSlot resolving source slot (sum (fmap DamageEvent.amount dealtEvents)))
  -- Incinerate's "a creature dealt damage this way": the OBJECTS the settled
  -- events reached (CR 120.3), so one whose damage was all prevented (CR
  -- 615.6) is not among them. Bound onto `resolving` as a group, Destroy's
  -- `permanents` shape; nothing is bound when nothing was damaged.
  Monad.forM_ mDamaged $ \slot -> do
    let hit = ListUtils.nubOrd (Maybe.mapMaybe (Recipient.objectOf . DamageEvent.target) dealtEvents)
    Monad.unless (null hit) (State.modify' (Common.bindObjectsSlot resolving slot (Seq.fromList hit)))

-- CR 701.14. Every clause of the rule is one line here, and none of them is a
-- read of what the effect IS: the amounts come off the projection, the kind is
-- data, and the pair guard is arithmetic on two Maybes.
fight :: (Game Result -> Game ()) -> (Game Result -> Game ()) -> Game Result -> Map.Map SlotName (Set Recipient) -> Fight.Fight -> Game ()
fight runPreventionRiders runReplacementEffects runSubgame legal (Fight.MkFight firstSlot secondSlot) = do
  gs <- State.get
  -- CR 701.14b, and it is a guard on the PAIR: "if one or both creatures
  -- instructed to fight are no longer on the battlefield or are no longer
  -- creatures, NEITHER of them fights or deals damage". Its second sentence --
  -- an illegal target -- is legalOne's Nothing, CR 608.2b having already
  -- narrowed the slot.
  --
  -- Both powers read off the SAME pre-effect state, which is CR 701.14a's
  -- "each of those creatures deals damage equal to its power": a fight whose
  -- first blow shrank the second creature would read the wrong number.
  let fighter slot = do
        recipient <- legalOne slot legal
        oid <- Recipient.objectOf recipient
        Monad.guard (Set.member oid (GameState.battlefield gs))
        Monad.guard (Projection.isCreatureOf oid gs)
        power <- Projection.powerOf oid gs
        pure (oid, power)
  case (fighter firstSlot, fighter secondSlot) of
    (Just (oneId, onePower), Just (twoId, twoPower)) -> do
      -- CR 701.14d: "the damage dealt when a creature fights ISN'T COMBAT
      -- DAMAGE", so DamageKind.Noncombat and never the combat damage path.
      -- Each creature is its own blow's source (CR 120.2b), which is what makes
      -- an ordinary fight two dealers where an Effect.DealDamage has one -- and
      -- a self-fight one dealer again.
      --
      -- Zero is dropped rather than dealt (CR 120.8), the same guard the
      -- DealDamage arm above writes.
      let blow dealer victim amount =
            if amount > 0
              then [Event.damageEvent gs DamageKind.Noncombat dealer (Recipient.ToCreature victim) (Integer.toNaturalSaturating amount)]
              else []
          events
            -- CR 701.14c: "if a creature fights itself, it deals damage to
            -- itself equal to TWICE its power" -- ONE event, not two of its
            -- power. Every observer that sums (marked damage, CR 120.4a's
            -- excess, lifelink, CR 615.7's amount-based shield) agrees either
            -- way; one that counts events (CR 122.1c's shield counters, a
            -- damage trigger) does not, which is why the rule bothers to say
            -- it.
            --
            -- Both reads of the same power off the same pre-effect state, so
            -- doubling one is the same number as summing the two; written as
            -- the rule words it.
            | oneId == twoId = blow oneId oneId (2 * onePower)
            | otherwise = blow oneId twoId onePower <> blow twoId oneId twoPower
      -- ONE batch: CR 701.14a's "each of those creatures deals damage" is one
      -- action, so the two blows land simultaneously and a creature that dies
      -- to the first still dealt the second.
      Monad.unless (null events) $ do
        Monad.void (Damage.applyDamage events)
        -- The DealDamage arm's two drains, and for its reasons: a fight is an
        -- ordinary damage event, so a rewrite or a shield that applied to it
        -- runs inside this resolution rather than waiting for the next one.
        -- CR 614.1a's instead-effects first, then CR 615.5's riders.
        runReplacementEffects runSubgame
        runPreventionRiders runSubgame
    _ -> pure ()

modifyTarget :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> ModifyTarget.ModifyTarget (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()
modifyTarget resolving source controller legal chosen (ModifyTarget.MkModifyTarget duration modification ref each) = do
  -- The affected objects are enumerated once, by the same sweep every
  -- ObjectRef-taking opcode uses. Nothing to affect (an illegal slot per CR
  -- 608.2b, a set that matched nothing) arrives as the empty list.
  --
  -- The CHOSEN ref is asked through askingObjects instead, Effect.Pair's
  -- reason: CR 608.2d's choice is an ask, which the pure sweep cannot make.
  -- Mirkwood Trapper's "that player chooses an attacking creature. It gets
  -- +2/+0" is the reader.
  affected <- Common.askingObjects resolving source controller legal chosen ref
  State.modify' $ \gs ->
    case Common.frozenAffected gs affected of
      [] -> gs
      targets -> case Expiry.arm (Game.readingAcquisition resolving source) legal controller source duration gs of
        -- CR 611.2b: the duration never started, so nothing is stored.
        Nothing -> gs
        Just expiry ->
          -- CR 611.2c: the swept ids are frozen into the stored effect, so the
          -- set never changes afterwards. ONE effect over the whole set, which
          -- is one timestamp for CR 613.7 to order.
          --
          -- CR 608.2h / 611.2d: the VALUE is locked here too, against the
          -- SOURCE (CR 113.7a) and its controller, not an affected object.
          -- CR 601.2b's announced X is read off `resolving` instead, since
          -- only the ability object holds it. A quantity that cannot be
          -- evaluated now is undetermined for good, so nothing is stored.
          --
          -- Through effectContext and NOT Filter.contextFor, so the resolution's
          -- own slot bindings ride along: Rush of Blood's X is the power of the
          -- creature in its own target slot, and a slotless context answers
          -- Nothing and stores nothing at all.
          --
          -- With `each` named, CR 701.10b's "that creature's power" instead: the
          -- freeze runs once per affected object with that object bound under
          -- the name, and each gets an effect of its own value.
          --
          -- A name the modification states for the resolving ability's own
          -- object is that object's ability as acquired beside it
          -- (Binding.nameAsRead), so an acquired Gliding Licid's "loses this
          -- ability" names that ability alone; a name stated for another
          -- object stays as written. A REGRESSION FENCE: the Licid's attach
          -- re-timestamps the grant past the removal (CR 613.7e), so no
          -- board observes the qualified name.
          let context = effectContext gs resolving controller source legal (slotBindings resolving gs)
              asRead = case modification of
                Modification.LoseNamedAbility name | targets == [source] -> Modification.LoseNamedAbility (Binding.nameAsRead (resolvingAbilityName resolving gs) name)
                _ -> modification
              freezeFor objs ctx = (objs, Projection.freezeQuantities (effectViewOf source legal gs) gs resolving source ctx asRead)
              frozenSets = case each of
                Nothing -> [freezeFor targets context]
                Just slot -> [freezeFor [t] (effectContextNaming slot t gs resolving controller source legal (slotBindings resolving gs)) | t <- targets]
              store objs g m =
                let (ts, g1) = Game.freshTimestamp g
                    eff =
                      ContinuousEffect.MkContinuousEffect
                        { ContinuousEffect.source = source,
                          ContinuousEffect.timestamp = ts,
                          ContinuousEffect.expiry = expiry,
                          ContinuousEffect.modification = m,
                          ContinuousEffect.affected = Affected.TheseObjects (Set.fromList objs)
                        }
                 in g1 {GameState.continuousEffects = eff : GameState.continuousEffects g1}
              storeSet g (objs, frozen) = case frozen of
                Nothing -> g
                Just m -> List.foldl' (store objs) g (Common.expandGrant resolving source gs m)
           in List.foldl' storeSet gs frozenSets

-- CR 608.2d: a word swap is not among CR 601.2b-d's announcements, so the
-- choice is made here, as the effect applies. Observable: a countered Magical
-- Hack is never asked.
changeText :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ChangeText.ChangeText -> Game ()
changeText resolving source controller legal (ChangeText.MkChangeText families forbidden slot duration) = case legalOne slot legal of
  Just recipient -> case Recipient.objectOf recipient of
    Nothing -> pure ()
    Just target -> do
      gs0 <- State.get
      let decider = Decide.deciderFor controller gs0
          -- CR 612.2: which words are offered is a CLASSIFICATION of the
          -- effect (which families), never its identity; the "can't be Wall"
          -- restriction rides in from the data as `forbidden`.
          question = Prompt.ChooseWordSwap decider controller resolving slot families forbidden
      answer <- Game.choose question
      -- CR 612.2: an unswappable answer is filtered, not trusted (the
      -- chooseAmong posture), and a card leaving no legal swap changes
      -- nothing. Proved by Parun.CounterspellSpec's TextSwapLegality.
      Foldable.for_ (if TextWord.swappable families forbidden answer then Just answer else TextWord.firstSwap families forbidden) $ \(from, to) -> State.modify' $ \gs ->
        -- CR 611.2a's Indefinite unless the card states a duration (Crystal
        -- Spray's "until end of turn"), armed through Expiry like the other
        -- storing arms; Nothing when the duration has already passed.
        case Expiry.arm (Game.readingAcquisition resolving source) legal controller source duration gs of
          Nothing -> gs
          Just expiry ->
            -- CR 611 / 612: a continuous effect over the one target, with the
            -- announced (from, to) baked in. Resolve constructs the
            -- Modification but never cases on one.
            let (ts, gs1) = Game.freshTimestamp gs
                eff =
                  ContinuousEffect.MkContinuousEffect
                    { ContinuousEffect.source = source,
                      ContinuousEffect.timestamp = ts,
                      ContinuousEffect.expiry = expiry,
                      ContinuousEffect.modification = Modification.ChangeWord (ChangeWord.MkChangeWord from to),
                      ContinuousEffect.affected = Affected.TheseObjects (Set.singleton target)
                    }
             in gs1 {GameState.continuousEffects = eff : GameState.continuousEffects gs1}
  -- CR 608.2b: an illegal target is not affected by this part, and CR 608.2d's
  -- announcement belongs to an effect that IS applied, so nothing is asked.
  _ -> pure ()

-- The second place mana is PRODUCED into a pool (CR 106.3) -- the MoveMana arm
-- below puts mana in one without producing any. An ACTIVATED mana ability is
-- applied by Cost.tapForMana and never resolves (CR 605.3b), and CR 605.4a's
-- triggered one reaches this arm through performTriggeredManaAbility rather
-- than off the stack; what resolves here in the ordinary way is a triggered
-- producer CR 605.1b leaves out, Burning-Tree Emissary's shape.
--
-- CR 605.1b's "mana being added to a player's mana pool" is recorded here as
-- well as on Cost's road, one event per recipient, carrying
-- ManaAddedCause.Resolution so that CR 605.5a can tell the two apart
-- (Parun.Engine.ManaAbility.firedFromManaAbility). A trigger watching it is
-- therefore an ORDINARY triggered ability and uses the stack, which is what
-- Parun.ManaSpec's "Caged Sun" group proves off Crumbling Vestige.
--
-- CR 605.4a's inline road reaches this arm too, and its addition is a
-- Resolution like any other: CR 605.5a's question is whether an ACTIVATED
-- mana ability added the mana, and a triggered mana ability is not one. What
-- the activation itself added is recorded by Parun.Engine.Cost.tapForManaWith
-- instead, and carries ManaAddedCause.ManaAbility.
--
-- CR 106.4: into the pool of the player the effect names, read through
-- playerRefPlayers like every other slot read (CR 608.2b). The type and the CR
-- 106.3 tags come from the ability's SOURCE, the payment path's own readers.
-- The RETENTION (CR 106.4) and CR 106.6's two clauses -- the restriction and
-- the rider -- are what come off the INSTRUCTION instead, stamped onto every
-- unit it adds (CR 106.6a).
--
-- The RIDER's stamp here is a regression fence rather than a proven behaviour:
-- both printings that write one (Boseiju, Who Shelters All and Delighted
-- Halfling) are mana abilities and take the inline CR 605.3b road instead, so
-- neutralising this line leaves the whole suite green. CR 106.6a states it
-- anyway, which is why the line is here. The CR 607.2a sourceLastExiled stamp
-- is a fence for the same reason: Ice Cauldron, its one producer, is a mana
-- ability too. So is the spend trigger's: Pyromancer's Goggles is one.
addMana :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ManaAddition.ManaAddition -> Game ()
addMana resolving source controller legal (ManaAddition.MkManaAddition ref production count retention restriction rider whenSpent) = do
  gs0 <- State.get
  -- CR 106.3: how many units this ONE instruction adds, read off the board at
  -- RESOLUTION rather than off the card -- Cabal Coffers' "for each Swamp you
  -- control". Parun.Engine.Mana.manaOptionsOfGiven evaluates the same quantity
  -- for CR 605.3b's inline road, so the offer and the addition measure one
  -- board. A negative count adds nothing, and an undeterminable one reads 0.
  let howMany = max 0 (Integer.toIntSaturating (Maybe.fromMaybe 0 (Quantity.evaluateFor (effectViewOf source legal gs0) (effectContext gs0 resolving controller source legal (slotBindings resolving gs0)) gs0 resolving source count)))
      unitOf manaType =
        ManaUnit.MkManaUnit
          { ManaUnit.manaType = manaType,
            ManaUnit.tags = Mana.productionTagsGiven Map.empty source gs0,
            ManaUnit.retention = retention,
            ManaUnit.restriction = restriction,
            ManaUnit.rider = rider,
            ManaUnit.spendTrigger = Mana.spendTriggerOf controller source gs0 =<< whenSpent,
            ManaUnit.sourceChoices = Mana.sourceChoicesOf source gs0,
            ManaUnit.sourceLastExiled = Mana.lastExiledWith (resolvingAbilityName resolving gs0) source gs0
          }
      -- CR 605.1b's event, per recipient. Nothing is recorded where the
      -- instruction added no mana: an addition of none is no addition, and CR
      -- 605.1b's clause is about mana that arrived.
      recordAdded pid manaTypes =
        Monad.when (howMany > 0) $
          State.modify'
            ( Event.recordEvent
                ( GameEvent.ManaAdded
                    ( ManaAdded.MkManaAdded
                        { ManaAdded.player = pid,
                          ManaAdded.source = source,
                          ManaAdded.mana = manaTypes,
                          ManaAdded.cause = ManaAddedCause.Resolution
                        }
                    )
                )
            )
  case Mana.produced source gs0 production of
    -- A settled run needs no question; the COUNT is how many times this one
    -- instruction adds it, and a clause adding mana of two DIFFERENT types
    -- writes two effects, run in printed order (CR 608.2c) -- except CR
    -- 607.2e's noted run and CR 701.10f's doubled pool, each one instruction
    -- of mixed types (Ice Cauldron, Doubling Cube). An empty run is CR
    -- 607.2d's "the chosen color" with nothing chosen, nothing noted or an
    -- empty pool: adding nothing is the honest answer.
    Mana.Settles run ->
      let units = concat (replicate howMany (fmap unitOf run))
          recipients = playerRefPlayers legal resolving source controller gs0 ref
       in Monad.unless (null run) $ do
            State.modify' (\gs -> foldr (\pid -> Mana.addMana pid units) gs recipients)
            Monad.mapM_ (\pid -> recordAdded pid (Set.fromList run)) recipients
    -- Several types is CR 105.4's choice, and it is the RECIPIENT's: CR 106.3
    -- has the effect instruct a player to add the mana, and CR 106.4 puts it in
    -- that player's pool. CR 101.4: several recipients are asked in APNAP
    -- order, with apnapOrder supplying the ORDER and the ref the MEMBERSHIP; a
    -- recipient apnapOrder does not name keeps its place at the end rather than
    -- losing the mana CR 106.4 puts in their pool.
    --
    -- CR 105.4's choice is made ONCE for the whole instruction, which is what
    -- "two mana of any one color they choose" says (Stadium Vendors): the
    -- count replicates the unit the answer settled rather than asking again.
    Mana.Offers offered ->
      let named = playerRefPlayers legal resolving source controller gs0 ref
          ordered = filter (\pid -> List.elem pid named) (Game.apnapOrder gs0)
          recipients = ordered <> filter (\pid -> List.notElem pid ordered) named
       in Monad.forM_ recipients $ \pid -> do
            -- Through Game.chooseAmong, the instruction being mandatory.
            -- Mana.produced answers Offers only for two or more types.
            picked <- Game.chooseAmong (\decider who -> Prompt.ChooseManaType decider who resolving) pid (NonEmpty.toList offered)
            let manaType = Maybe.fromMaybe (NonEmpty.head offered) picked
            State.modify' (Mana.addMana pid (replicate howMany (unitOf manaType)))
            recordAdded pid (Set.singleton manaType)

-- CR 608.2c's instruction, carried out by somebody other than this spell's
-- controller: Drain Power's first sentence has the TARGETED player activate a
-- mana ability of each of their lands. Each activation then runs by CR 605.3,
-- and CR 602.2 is what makes every choice in it that player's -- only an
-- object's controller can activate its activated ability.
--
-- Through Cost.tapForMana, the funnel EVERY activation goes through, so this
-- road cannot come apart from the payment one: WHICH mana ability and which
-- colour are asked of the permanent's controller (Prompt.ChooseManaYield's
-- decider), the ability's own cost is paid by that player, CR 605.3b keeps it
-- off the stack, CR 405.6c's other effects run inline and CR 605.4a's triggered
-- mana abilities are applied where they stand. The engine picks none of it.
--
-- WHICH permanents: the ones each actor CONTROLS matching the filter, which is
-- where "they control" lives -- the filter itself is read in the SPELL's
-- context, where CR 109.5's "you" is its controller and not the actor
-- (Parun.Types.ActivateManaAbilities' haddock). Frozen before the first
-- activation, so a land that pays for another's ability by sacrificing itself
-- does not shorten the list mid-sweep; a permanent gone by the time its turn
-- comes simply offers nothing.
--
-- The ORDER within one actor's batch is the ACTOR's: CR 605.3a says when a
-- player may activate a mana ability and not in which order several of them
-- are activated, and CR 609.3's "as much as possible" makes an order that
-- leaves one permanent's ability unpayable a legal outcome rather than a
-- licence to reorder around it. Observable wherever one land's mana pays for
-- another's ability -- Mystic Gate after a Plains, which Parun.ManaSpec's
-- "CR 605.3a the order the batch is activated in is the targeted player's"
-- case proves.
--
-- Asked at two or more, ON THE COUNT ALONE, as Prompt.OrderTimestamps' caller
-- is: whether two orders are distinguishable turns on choices this actor has
-- not made yet -- which mana ability of each permanent (Prompt.ChooseManaYield)
-- and what its cost then leaves in the pool -- so no gate here can tell. A
-- batch of one is one order.
activateManaAbilities :: (Game Result -> ManaAbilityPerformer.ManaAbilityPerformer) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ActivateManaAbilities.ActivateManaAbilities -> Game ()
activateManaAbilities performManaAbility runSubgame resolving source controller legal (ActivateManaAbilities.MkActivateManaAbilities ref filter_) = do
  gs0 <- State.get
  let matching = battlefieldMatching legal resolving controller source gs0 filter_
      theirs pid = filter (\oid -> Projection.controllerOf oid gs0 == Just pid) matching
  -- CR 101.4's APNAP order over several actors, apnapPlayersOf's own
  -- intersection; Drain Power names one.
  Monad.forM_ (Common.apnapPlayersOf ref legal resolving source controller gs0) $ \pid -> do
    let batch = theirs pid
    ordered <- case batch of
      _ : _ : _ -> do
        gs1 <- State.get
        answer <- Game.choose (Prompt.OrderManaActivations (Decide.deciderFor pid gs1) pid batch)
        -- Filtered, not trusted: Game.permute keeps the gathered order for an
        -- answer that is not a permutation of the offered indices.
        pure (Game.permute batch answer)
      _ -> pure batch
    Monad.mapM_ (Cost.tapForMana (performManaAbility runSubgame) pid) ordered

-- CR 106.13: one player loses all their unspent mana and another adds "the mana
-- lost this way". WHOLE UNITS cross (Mana.moveMana), which is the rule's second
-- sentence -- what produced the mana, its CR 106.4 retention and both of CR
-- 106.6's clauses are unchanged because nothing is re-derived.
--
-- The parenthetical -- "these may be the same player" -- falls out of the order
-- Mana.moveMana writes in: the pools empty first, so a card naming one player
-- on both sides nets the mana once. No gainer is CR 106.4's plain loss (Mana
-- Short).
moveMana :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> MoveMana.MoveMana -> Game ()
moveMana resolving source controller legal (MoveMana.MkMoveMana fromRef toRef) = do
  gs <- State.get
  Mana.moveMana (Common.apnapPlayersOf fromRef legal resolving source controller gs) (foldMap (\ref -> Common.apnapPlayersOf ref legal resolving source controller gs) toRef)

search :: (Game Result -> ManaAbilityPerformer.ManaAbilityPerformer) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Search.Search -> Game ()
search performManaAbility runSubgame resolving source controller legal (Search.MkSearch searcherRef ownerRef zones outside quantity filter_ upTo destination subject foundSlot differentIn exactly andOr) =
  -- CR 701.23a: match each candidate through its own CR 613 projection --
  -- rule 613.1 names no zone, so a card in any of the searched zones is folded
  -- exactly as a permanent is, and CR 208.2a's characteristic-defining power
  -- rides along at layer 7a.
  --
  -- Through effectContext and NOT Filter.contextFor, so the resolution's own
  -- slots ride along and a search filter naming one is answerable: Bifurcate's
  -- "with the same name as target nontoken creature" is CR 201.2a's
  -- Filter.Shares Name Bound over the slot the spell targeted, which a bare
  -- context would have answered False for on every card in the library.
  -- Parun.ResolveSpec's Bifurcate cases are what prove it.
  --
  -- A FUNCTION of the board rather than a value, so the slots come with it: CR
  -- 608.2c has the clauses carried out in order, so a slot an earlier clause of
  -- this same resolution bound is read here rather than as it stood when the
  -- arm was entered.
  --
  -- CR 109.5's "you" is the resolving controller, which effectContext supplies
  -- as the perspective; a search filter in the pool names no player, so no
  -- candidate's answer turns on it.
  --
  -- CR 701.3a: one candidate's VIEW carries the field no projection can fill --
  -- whether the CANDIDATE could legally be attached to the object this
  -- instruction fixes (Auratouched Mage's "an Aura card that could enchant
  -- it"). WHICH object that is comes from Search.subject: the searching
  -- ability's own SOURCE where the card says "it" of itself (CR 113.7), and
  -- otherwise the one object a slot this resolution has bound names --
  -- Sovereigns of Lost Alara's "that creature", CR 506.5's lone attacker, which
  -- its trigger stamped under Binding.attackingCreature. Answered by
  -- Attach.attachableWithLastKnown, whose live half is the same function the
  -- move goes through, so the offer and the move cannot disagree -- and whose
  -- other half is CR 608.2h: a source killed while its own trigger was on the
  -- stack is read as it MOST RECENTLY existed, so the search still finds the
  -- card that could have enchanted it, and putFound's own CR 608.2h branch is
  -- where that card then goes. Lazy, so a filter that never names
  -- Filter.CanAttachToSubject pays nothing for it.
  --
  -- A slot naming no object, or more than one, leaves rule 701.3a's question
  -- with nothing to be about, and the atom is False for every candidate -- a
  -- search that finds nothing rather than one that finds anything. The same
  -- reading putFound takes for where the card then goes, so the offer and the
  -- move agree there too.
  --
  -- No recursion to bound: this is called from a resolution rather than from
  -- inside a CR 613 fold, so the projections that question reaches start fresh.
  --
  -- CR 201.4's chosen names ride along with the slots, effectContext filling
  -- them for every position of a resolution alike (Ancient Vendetta's "cards
  -- with that name"). A function of the board rather than a value for the same
  -- reason the slots are: the clause that chose the name is an earlier one of
  -- this same resolution.
  let searchContext g = effectContext g resolving controller source legal (slotBindings resolving g)
      subjectOf g = maybe (Just source) (\slot -> Filter.slotOneObject slot (searchContext g)) subject
      viewOfCandidate searcher g oid =
        (Projection.viewOfObject oid g)
          { Filter.canAttachToSubject = Maybe.maybe False (\host -> Attach.attachableWithLastKnown searcher oid host g) (subjectOf g)
          }
      matches1 searcher g oid = Filter.matches (searchContext g) (viewOfCandidate searcher g oid) filter_
      -- CR 400.2: the library and the hand are the hidden zones. CR 701.23b,
      -- CR 701.23c and CR 701.23d are each scoped to a hidden zone, so this is
      -- what decides, PER ZONE, whether a find may be declined.
      isHidden zone = zone == Zone.Library || zone == Zone.Hand
      -- The places the printed "and/or" names: the zones, and outside the
      -- game where the card says so (CR 701.23j) and its destination can take
      -- a card from there -- see outsideArrival.
      places =
        Set.map SearchPlace.InZone zones
          <> (if outside && Maybe.isJust (Common.outsideArrival destination) then Set.singleton SearchPlace.OutsideTheGame else Set.empty)
   in do
        gs0 <- State.get
        -- Search.searcher names who searches; Search.owner names whose zones
        -- are read and whose library is shuffled. The searcher is prompted and
        -- offered CR 601.3's cast. Neither is `controller` except where a ref
        -- says so. CR 701.23i supplies the order: apnapOrder supplies the ORDER
        -- and the ref the MEMBERSHIP, for searchers and owners alike.
        --
        -- CR 701.23i and CR 101.4: every searcher looks at the same cards and
        -- decides in APNAP order, and only then does anything move. So the
        -- first pass below only decides; the finds are put and the libraries
        -- shuffled after the last decision, and a later searcher of the same
        -- library is offered what an earlier one found.
        let inApnapOrder r =
              let named = playerRefPlayers legal resolving source controller gs0 r
               in filter (\pid -> List.elem pid named) (Game.apnapOrder gs0)
            searchers = inApnapOrder searcherRef
            -- "Each player searches THEIR library" (Jungle Wayfinder) is ONE
            -- instruction applied per player, not the cross product of two
            -- folds: the zones read are whichever searcher this pass has
            -- reached. Rule 701.23a says only how to look, so which player's
            -- zones those are comes from the card's own sentence rather than
            -- from the rule. That is Parun.Types.PlayerRef.Candidate's reading,
            -- and the substitution is the same move Parun.Engine.Quantity
            -- .forCandidate makes for a per-player amount. Every other ref
            -- names a set of its own, so Extract's You/InSlot pair still
            -- crosses -- one searcher over one owner.
            ownersFor searcher = case ownerRef of
              PlayerRef.Candidate -> [searcher]
              _ -> inApnapOrder ownerRef
            -- How many cards this search may find (CR 701.23a), evaluated ONCE
            -- before the loop: the card prints one instruction with one count
            -- however many zones it names, so a two-zone search caps the two
            -- together. An unevaluable or non-positive quantity comes
            -- out as 0. A search that states no count at all -- Mana Severance's
            -- "any number of land cards" -- comes out as Nothing, and is bounded
            -- by what the searched zones hold, which is CR 701.23a's "all cards
            -- in that zone".
            cap = fmap evaluateCap quantity
            evaluateCap q = case Quantity.evaluateFor (effectViewOf source legal gs0) (effectContext gs0 resolving controller source legal (slotBindings resolving gs0)) gs0 resolving source q of
              Just n | n > 0 -> Integer.toNaturalSaturating n
              _ -> 0
        decisions <- fmap concat . Monad.forM searchers $ \searcher -> Monad.forM (ownersFor searcher) $ \owner -> do
          -- CR 101.2: a player who can't search libraries does not, and finds
          -- nothing there. Asked BEFORE CR 601.3's offer below, which is made
          -- WHILE SEARCHING. The rest of the instruction still happens -- CR
          -- 701.23 says only how to look, so the shuffle is the card's own.
          --
          -- The prohibition names LIBRARIES (Leonin Arbiter), so it removes
          -- that one zone rather than the whole instruction: a prohibited
          -- searcher still looks through the graveyard the same card named.
          --
          -- Asked per (searcher, owner) pair and handed this resolution's own
          -- controller, because a prohibition narrows on both axes: whose
          -- library is looked through, and who controls the spell or ability
          -- causing the look (Ashiok, Dream Render). `controller` is CR
          -- 405.4's controller of the object whose instructions these are.
          prohibited <- State.gets (PlayerEffect.prohibitsSearching searcher owner controller)
          -- The printed "and/or": the searcher picks which of the zones the
          -- card names to look through -- Delivery Moogle's "your library
          -- and/or graveyard" -- and the rest of the instruction, the shuffle
          -- included, follows the CHOICE rather than the printing.
          --
          -- Filtered, not trusted, and never empty: an answer naming a zone
          -- the card did not, or naming none at all, takes every named zone.
          -- Prompt.ChooseSearchZones says why the empty answer is not the
          -- searcher's to give. Raised only where the card prints "and/or"
          -- (Search.andOr) over two or more places: Ancient Vendetta's "and"
          -- looks through every one.
          --
          -- Offered over the card's own zones rather than over the
          -- prohibition-filtered set just below, since CR 101.2 stops the
          -- looking and not the card's other instructions -- the shuffle among
          -- them. Read LIVE rather than off gs0: CR 601.3's cast happens
          -- during an earlier searcher's pass, so a later pass asks over a
          -- board this resolution has already moved.
          --
          -- Outside the game is one of the places on offer where the card
          -- names it (CR 701.23j), though CR 400.11 makes it no zone: Invasion
          -- of Arcavios's searcher may take it alone, and then shuffles
          -- nothing and is forced to find nothing.
          chosenPlaces <-
            if Set.size places < 2 || not andOr
              then pure places
              else do
                gsZones <- State.get
                answer <- Game.choose (Prompt.ChooseSearchZones (Decide.deciderFor searcher gsZones) searcher places)
                let kept = Set.intersection answer places
                pure (if Set.null kept then places else kept)
          let chosenZones = Set.fromList [zone | SearchPlace.InZone zone <- Set.toList chosenPlaces]
              searchedZones = if prohibited then Set.delete Zone.Library chosenZones else chosenZones
              -- CR 701.23j: "a card THEY own", so the pool is the searcher's,
              -- whoever `owner` names. Read LIVE, the zones' reason above.
              lookOutside = Set.member SearchPlace.OutsideTheGame chosenPlaces
              -- "While they're searching their library" (Opposition Agent):
              -- a searcher looking through their OWN library, which CR
              -- 101.2's prohibition above can take away.
              ownLibrary = searcher == owner && Set.member Zone.Library searchedZones
          -- CR 723.2: for the rest of this searcher's pass, the player whose
          -- row says so makes their decisions (CR 723.5) -- the find, and CR
          -- 601.3's offer. A control row rather than a local decider, so every
          -- prompt raised inside the pass, the offered cast's included, reads
          -- it through Decide.deciderFor. Derived as the pass begins: nothing
          -- inside one search instruction can end it, since state-based
          -- actions wait for priority (CR 704.3) and the controlled player
          -- pays only with their own resources (CR 723.5a).
          searchController <-
            if ownLibrary
              then State.gets (PlayerEffect.searchingController searcher)
              else pure Nothing
          let searchControl (you, stamp) = PlayerControl.MkPlayerControl {PlayerControl.decider = Decider.MkDecider you, PlayerControl.duration = ControlDuration.WhileSearching, PlayerControl.manaFromLandsOnly = False, PlayerControl.timestamp = stamp}
          Foldable.for_ searchController (State.modify' . Common.pushControl searcher . searchControl)
          -- CR 616.1: which Opposition Agent's exile replaces where the finds
          -- go, chosen by the searcher -- under the control row just pushed,
          -- whoever decides for them -- and elided at one.
          exiler <-
            if ownLibrary
              then State.gets (PlayerEffect.exilersWhileSearching searcher) >>= Game.chooseAmong (\decider who -> Prompt.ChoosePermanent decider who source) searcher
              else pure Nothing
          outsideAvailable <-
            if lookOutside
              then State.gets (Event.outsideOffer filter_ source searcher)
              else pure Map.empty
          -- CR 601.3 (Panglacial Wurm): the chance to cast is offered AT THE
          -- SEARCH, not when the resolution began, so earlier effects of the
          -- resolution have already happened. Both spells and abilities reach
          -- here. The Wurm's "while you're searching your library" makes the
          -- offer the SEARCHER's, only where the library being searched is
          -- their own, and only where a LIBRARY is among the zones being looked
          -- through.
          --
          -- That last conjunct is a REGRESSION FENCE rather than a proven
          -- behaviour. It is now REACHABLE -- a searcher may take the graveyard
          -- half of an "and/or" alone -- but observing it needs a castable
          -- library card on the board at the same time, which no case builds;
          -- removing it reddens nothing.
          --
          -- CR 701.23a: the searcher looks at ALL cards in each zone searched,
          -- not only the matches (Event.look). The scenario
          -- visibility/cr-701-23a-private-look-rampant-growth-shows-the-whole-library-to-its-searcher-alone
          -- is the proof.
          --
          -- Both come AHEAD of the zero-cap shortcut below: a search for zero
          -- cards is still a search, which looks and may cast, though it finds
          -- nothing. The scenario
          -- visibility/cr-701-23a-private-look-oreskos-explorer-s-search-for-none-still-looks
          -- is the proof.
          Monad.unless (Set.null searchedZones) $ do
            Monad.when (searcher == owner && Set.member Zone.Library searchedZones) (Cast.castWhileSearching (performManaAbility runSubgame) searcher)
            looking <- State.get
            Monad.forM_ (Set.toAscList searchedZones) $ \zone -> Monad.mapM_ (Event.look searcher) (Game.zoneMembers zone owner looking)
          -- A cap of zero asks nothing and finds nothing: one legal answer is
          -- no choice to put to a player. An unbounded search has no such
          -- shortcut -- its cap is not known until the zones are read.
          (found, foundOutside) <-
            if (Set.null searchedZones && Map.null outsideAvailable) || cap == Just 0
              then pure ([], [])
              else do
                gs <- State.get
                -- ONE prompt over the union, not one per zone: the card prints
                -- one instruction with one count, and asking per zone would cap
                -- per zone. The zone is kept alongside its candidates because
                -- CR 701.23b's permission is a property of the ZONE.
                let byZone = fmap (\zone -> (zone, filter (matches1 searcher gs) (Game.zoneMembers zone owner gs))) (Set.toAscList searchedZones)
                    matches = concatMap snd byZone
                    outsideCopies = sum (Map.elems outsideAvailable)
                    -- CR 701.23a bounds an unbounded search by the places: every
                    -- card the filter admits is findable, and no more.
                    capHere = Maybe.fromMaybe (List.genericLength matches + outsideCopies) cap
                    decider = Decide.deciderFor searcher gs
                    -- Search.exactly: the answer must be a group of as many
                    -- cards as the zones can give, up to the count (CR 101.1,
                    -- 609.3). Validated, not filled: which cards make up the
                    -- group is the searcher's choice.
                    required = Common.mostDiffering differentIn gs capHere matches
                    fills given = Common.differing differentIn gs given == given && List.genericLength given == required
                    -- RE-ASKED when short, Parun.Engine.Engine's CR 603.3d
                    -- shape: a repeat of an answer already refused is taken
                    -- as it stands, since a pure decider repeats itself and
                    -- answering on its behalf is the one thing this may not
                    -- do. Keyed on the answer narrowed to the offer, so the
                    -- recursion terminates.
                    askExactly rejected = do
                      given <- ListUtils.nubOrd . filter (`List.elem` matches) <$> Game.choose (Prompt.Search decider searcher matches capHere)
                      if fills given || Set.member given rejected then pure given else askExactly (Set.insert given rejected)
                answer <-
                  if Set.null searchedZones
                    then pure []
                    else
                      if exactly
                        then askExactly Set.empty
                        else Game.choose (Prompt.Search decider searcher matches capHere)
                -- CR 701.23a: every card found is one the filter admits.
                -- Filtered, not trusted, deduplicated, and truncated to the cap.
                -- What a SHORT answer leaves is the difference between CR
                -- 701.23b and CR 701.23d, and it is settled PER ZONE: CR
                -- 701.23b, CR 701.23c and CR 701.23d each speak of a HIDDEN
                -- zone, and CR 400.2 makes the graveyard public, so a search of
                -- a graveyard must find what it can even where the same search
                -- of a library need not. CR 701.23b's own Splinter example says
                -- exactly that. So a short answer is COMPLETED from the matches
                -- the searcher passed over in the zones that may NOT be
                -- declined.
                --
                -- Only the FIRST of the three ways to decline is the rule's
                -- and so scoped to a hidden zone: CR 701.23b's "isn't required
                -- to find" for a filter stating a quality. Search.upTo -- a
                -- card's own "up to" -- and a search
                -- stating no quantity are the CARD's own permissions, printed
                -- over the whole instruction, so they hold in a public zone
                -- too; CR 701.23d cannot force the second either, a search
                -- stating no quantity not being one "simply for a quantity of
                -- cards".
                --
                -- Both are proven over a PUBLIC zone, where the first disjunct
                -- cannot answer for them: Bruna, Light of Alabaster's scenario
                -- (cr-701-3a-whole-card-bruna-light-of-alabaster-gathers-auras-
                -- as-she-attacks.json) leaves a Pacifism in her graveyard
                -- unchosen, and Ancient Vendetta's (cr-701-23a-whole-card-
                -- ancient-vendetta-s-up-to-lets-alice-leave-the-named-cards-in-
                -- bob-s-graveyard.json) two named cards in bob's.
                --
                -- Search.exactly validated its answer above, which is then the
                -- whole find: nothing completes it.
                let mayDecline zone = exactly || upTo || Maybe.isNothing cap || (isHidden zone && Filter.statesAQuality filter_)
                    -- Search.differentIn: "with different names" (CR
                    -- 201.2b), "with different powers", "don't share a mana
                    -- value". Filtered, not trusted: a card sharing a value
                    -- with one kept ahead of it is dropped. The completion
                    -- below is not held to it, which no card reaches: every
                    -- card in data/cards/ printing one says "up to" or
                    -- "exactly".
                    picked = List.genericTake capHere . Common.differing differentIn gs . ListUtils.nubOrd $ filter (\oid -> List.elem oid matches) answer
                    forced = concatMap snd (filter (not . mayDecline . fst) byZone)
                    filler = filter (\oid -> List.notElem oid picked) forced
                    -- CR 701.23j: the searcher "MAY choose" a card out there,
                    -- so nothing forces a find outside the game, and what the
                    -- zones' find left of the one count is its ceiling. Asked
                    -- AFTER that find and BEFORE the completion below, so a
                    -- card taken from outside is what spares a public zone's
                    -- match -- Invasion of Arcavios's searcher who wants her
                    -- sideboard's sorcery over her graveyard's.
                    outsideRoom = min (capHere - min capHere (List.genericLength picked)) outsideCopies
                outsidePicked <- case NonEmpty.nonEmpty (Map.keys outsideAvailable) of
                  Just candidates
                    | outsideRoom > 0 -> do
                        outsideAnswer <- Game.choose (Prompt.ChooseFromOutsideTheGame decider searcher candidates 0 outsideRoom)
                        pure (Event.settleOutside outsideAvailable 0 outsideRoom outsideAnswer)
                  _ -> pure []
                let room = capHere - min capHere (List.genericLength picked + List.genericLength outsidePicked)
                pure (picked <> List.genericTake room filler, outsidePicked)
          Foldable.for_ searchController (State.modify' . Common.popControl searcher . searchControl)
          pure (searcher, owner, chosenZones, found, foundOutside, exiler)
        -- Where the cards go is the CARD's instruction, not rule 701.23's;
        -- CR 701.23e says the same of the reveal. The searcher is the
        -- revealer (CR 701.20a), and the cards go in the order the searcher
        -- named them.
        --
        -- A card an earlier find has already moved is no longer in the zones
        -- this searcher looked through, and is skipped: two searchers of one
        -- library may find the same card (CR 701.23i), and it moves once, as
        -- the first of them in APNAP order sends it. Parun.ResolveSpec's
        -- Synthetic Shared Excavation case proves the card moves once; the
        -- skip itself is a REGRESSION FENCE, since that card exiles and the
        -- move of a ceased object (CR 400.7) already does nothing, so
        -- removing it reddens nothing.
        --
        -- Every card found moves as ONE event (CR 608.2f) on ONE board, the
        -- one the event began on, so the cards entering together see each
        -- other (CR 603.6a), take CR 613.7m's order as one batch
        -- (Event.together), and each CR 616.1 loop reads `before`. A
        -- REGRESSION FENCE: no board in the suite finds two cards that could
        -- observe each other, so removing the bracket or the board reddens
        -- nothing.
        before <- State.get
        arrivals <- Event.simultaneously . Event.together . fmap concat . Monad.forM decisions $ \(searcher, owner, chosenZones, found, foundOutside, exiler) -> do
          -- Read HERE rather than when the arm was entered, the reason the
          -- context above is a function of the board: CR 608.2c carries the
          -- clauses out in order, so the slot an earlier clause bound is read
          -- as it stands now.
          host <- State.gets subjectOf
          let stillThere gs oid = any (\zone -> List.elem oid (Game.zoneMembers zone owner gs)) (Set.toList chosenZones)
          fromZones <- fmap concat . Monad.forM found $ \oid -> do
            present <- State.gets (`stillThere` oid)
            case (present, exiler) of
              (False, _) -> pure []
              (True, Nothing) -> Common.putFound resolving before searcher host destination oid
              (True, Just agent) -> [] <$ (Common.exileFoundFor agent =<< Event.changeZoneInBatchReturning before oid Zone.Exile)
          -- CR 400.11b: a card found outside the game is brought in rather
          -- than moved, the reveal riding along as it arrives (#2450).
          fromOutside <- case (Common.outsideArrival destination, exiler) of
            (Nothing, _) -> pure []
            (Just (arrival, revealIt), Nothing) -> Event.bringChosen arrival revealIt searcher foundOutside
            (Just _, Just agent) -> [] <$ (Common.exileFoundFor agent . Seq.fromList =<< Event.bringChosen OutsideDestination.Exile False searcher foundOutside)
          pure (fromZones <> fromOutside)
        -- The shuffle is the CARD's instruction too (CR 701.23h, CR 701.24b).
        -- The library shuffled is the one that was READ, so the seat is the
        -- owner -- and only where a LIBRARY is among the zones a searcher
        -- CHOSE. Delivery Moogle's "if you search your library this way,
        -- shuffle" is that condition printed: a searcher who took the
        -- graveyard half alone shuffles nothing.
        --
        -- Read off chosenZones rather than searchedZones, since CR 101.2's
        -- prohibition stops the looking and not the card's other
        -- instructions.
        --
        -- ONCE per library, however many searchers read it: the card prints
        -- one "then shuffle" of that library, not one per searcher.
        --
        -- NOT where the destination is Reveal, which leaves the found cards
        -- in the library for a later clause to read or move: there the card
        -- prints its shuffle after those clauses (CR 608.2c), as its own
        -- Effect.Shuffle, so a found card is never shuffled while a later
        -- clause still names it -- CR 701.24b's exclusion, and CR 701.20d's
        -- new object for a card Grim Reminder leaves behind. Nor where it is
        -- Stay: Doomsday prints no shuffle at all, and a later clause of its
        -- own puts the finds on top. The scenario
        -- cr-701-23d-whole-card-doomsday-stacks-the-five-it-found-and-exiles-the-rest
        -- is the proof.
        --
        -- RevealThenTop's and Top's found cards are still in the library at
        -- its shuffle, and CR 701.24b leaves them out of it: not reordered,
        -- they stay the objects the search found until they are put on top,
        -- which reorders them (CR 701.20d). Several would go on top in the
        -- order their owner states (CR 401.4, arrangeInLibrary) -- a
        -- regression fence, no card in data/cards putting more than one into
        -- one library; Insidious Dreams would (gap #5394). The scenarios
        -- cr-701-24b-mystical-tutor-s-find-is-left-out-of-the-shuffle-and-put-on-top
        -- and, unrevealed and one library per searcher,
        -- cr-701-24b-scheming-symmetry-puts-each-searcher-s-find-on-top-of-their-own-library
        -- are the proof.
        let shuffled
              | not (Common.shufflesAfter destination) = []
              | otherwise = ListUtils.nubOrd [owner | (_, owner, chosenZones, _, _, _) <- decisions, Set.member Zone.Library chosenZones]
            leftOut
              | Common.putsOnTop destination = Set.fromList arrivals
              | otherwise = Set.empty
        Monad.forM_ shuffled (Event.shuffleLibraryExcept leftOut)
        placed <-
          if Common.putsOnTop destination
            then do
              onTop <- concat <$> traverse (\oid -> Foldable.toList <$> Event.changeZoneAttaching Nothing Set.empty oid Zone.Library LibraryPosition.Top Nothing TapState.Untapped Map.empty Nothing Nothing Facing.FaceUp False CarryOver.NotCarried False Seq.empty) (reverse arrivals)
              owners <- State.gets (\gs -> ListUtils.nubOrd (Maybe.mapMaybe (\oid -> fmap Object.owner (Game.lookupObject oid gs)) onTop))
              Monad.forM_ owners (\owner -> Common.arrangeInLibrary owner onTop owner)
              pure onTop
            else pure arrivals
        -- CR 608.2c: "that card" in a later clause, or in a delayed ability
        -- this resolution arms (CR 603.7c), is what arrived.
        Common.bindObjects resolving foundSlot placed

-- Exile every card in every graveyard as ONE event (CR 608.2f), so "one or
-- more cards leave your graveyard" fires once (CR 603.2c). "Every graveyard"
-- is CR 102.1's players still in the game, not the keys of
-- GameState.players, which keep a departed seat's row -- and CR 801.10's
-- within the controller's range, which CR 801.18 lifts for a planar source
-- (Plane.rangePerspective).
exileAllGraveyards :: ObjectId -> PlayerId -> Game ()
exileAllGraveyards source controller = do
  gs <- State.get
  let gyCards = concatMap (\pid -> Game.zoneMembers Zone.Graveyard pid gs) (Players.table (Plane.rangePerspective source controller gs) gs)
  Monad.void (Event.changeZonesTogether (fmap (\c -> (c, Zone.Exile)) gyCards))

-- CR 103.5b (Serum Powder): the count is the hand size BEFORE the exile, which
-- is why this is one opcode rather than an exile followed by a Draw. Both
-- halves go through the usual funnels, so a short deck still loses at the first
-- upkeep exactly as the mulligan redraw already does.
exileHandThenDraw :: PlayerId -> Game ()
exileHandThenDraw controller = do
  gs <- State.get
  let handIds = Game.zoneMembers Zone.Hand controller gs
  Monad.void (Event.changeZonesTogether (fmap (\oid -> (oid, Zone.Exile)) handIds))
  got <- Maybe.catMaybes <$> Monad.replicateM (length handIds) (Event.drawCardReturning controller)
  -- CR 603.12: the Draw arm's shortfall. A REGRESSION FENCE: nothing arms a
  -- reflexive after it.
  Monad.when (length got < length handIds) Common.fallShort

-- CR 607.2e: the note is the ACTIVATION's CR 602.2b payment -- recorded on
-- the ability object as Object.manaSpent -- filed against the SOURCE, whose linked
-- mana ability reads it back (ManaProduction.Noted). Ice Cauldron's ruling
-- counts the mana spent and not X, so a cost reduction changes nothing.
noteManaSpent :: ObjectId -> ObjectId -> Game ()
noteManaSpent resolving source = do
  spent <- State.gets (foldMap (Mana.Type.unwrap . Object.manaSpent) . Game.lookupObject resolving)
  State.modify' (\gs -> gs {GameState.notedMana = Map.insert source (Seq.fromList (fmap ManaUnit.manaType spent)) (GameState.notedMana gs)})

-- CR 727.1/727.1a: restart the game, with this ability's controller as the new
-- starting player; the rebuild lives in Setup, reached through a generic opcode
-- rather than Karn's identity. CR 727.4: this resolves several frames deep, and
-- the rebuild replaces the game those frames are running, so
-- GameState.restartSignal is how they unwind. CR 727.5: the exempted cards are
-- swept BEFORE the rebuild, the only state in which the exemption can be read;
-- putting them back is a separate effect of the same ability.
--
-- CR 727.6 needs no code of its own: a subgame runs in its own frame
-- (Parun.Engine.Engine.playSubgame), which a restart inside it cannot reach
-- out of, and the game loop exits the instant GameState.result is Just, so a
-- main-game effect can only ever read the restarted subgame's winner.
restartGame :: (Game Result -> HandActionPerformer.HandActionPerformer) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Maybe ObjectRef -> Game ()
restartGame performHandAction runSubgame resolving source controller legal exempt = do
  gs <- State.get
  let exempted = case exempt of
        Nothing -> Set.empty
        Just ref -> Set.fromList (objectRefObjects legal resolving controller source gs ref)
  Setup.restartGame (performHandAction runSubgame) exempted controller

-- CR 729.1/729.5: run the nested game to completion, then bind its outcome.
--
-- CR 729.1b: what the main game may read is the subgame's WINNER, so the slot
-- holds the winners (a player, or CR 104.2c's whole team) and a Drawn
-- subgame binds nothing -- Shahrazad's "each player who doesn't win" is
-- PlayerRef.EachPlayerExcept over that slot, and gets the drawn case for
-- free. The roster the complement is taken against is Game.stillPlaying's,
-- the set Setup.subgameStateFrom seated.
--
-- The winner is bound onto `resolving` -- the object ON THE STACK -- and not
-- onto `source`, because that is what the next effect's re-read looks at: both
-- resolveSpellWith and resolveModesWith re-read the stack object's bindings
-- before each effect. The two coincide for a spell, which resolveSpellWith
-- passes as both, and differ for an ability, whose source is the permanent it
-- came from (CR 113.7) -- so binding onto `source` left an ability's follow-on
-- reading an unbound slot; see #137.
--
-- That object may not survive the subgame it started: CR 729.4 offers the main
-- game's stack to a wish cast inside, so the subgame can take this very spell's
-- card. bindPlayerSlot files the winner off-object when that has happened and
-- liveBindings reads it back, which is CR 729.5's "finishes resolving, even if
-- it was created by a spell card that's no longer on the stack".
playSubgame :: Game Result -> ObjectId -> SlotName -> Game ()
playSubgame runSubgame resolving slot = do
  result <- runSubgame
  case result of
    Result.Won winner -> State.modify' (Common.bindPlayerSlot resolving slot (Set.singleton winner))
    -- CR 104.2c: each player on the winning team wins.
    Result.TeamWon team -> do
      gs <- State.get
      State.modify' (Common.bindPlayerSlot resolving slot (Map.keysSet (Map.filter (== team) (Teams.unwrap (Game.teams gs)))))
    Result.Drawn -> pure ()

-- CR 608.2d: "choose an opponent" (Skullwinder) or "choose a player" (Stadium
-- Vendors), announced as this effect is applied and bound so the sentence
-- after it can say "that player". NOT A TARGET (CR 115.10a), so nothing was
-- announced at CR 601.2c and the pick is made here, against the board as this
-- effect runs.
--
-- WHICH players are offered is the payload's PlayerScope, read through
-- PlayerEffect.playersInScope against CR 109.5's "you" -- the resolving
-- controller -- so this arm classifies the choice and never names a card: the
-- players still in the game within the controller's range (CR 102.1, 801.5a).
-- CR 102.2 leaves "an opponent" nothing to decide at two seats, where "a
-- player" there has two candidates and must be asked. The ask is
-- Players.chooseOne. Nobody in scope binds nothing, so the following sentence
-- names no player and does nothing (CR 101.3).
choosePlayer :: ObjectId -> ObjectId -> PlayerId -> ChoosePlayer.ChoosePlayer -> Game ()
choosePlayer resolving source controller choice = do
  gs <- State.get
  let slot = ChoosePlayer.slot choice
  chosenPlayer <- Players.chooseOne controller source Nothing (Maybe.fromMaybe [] (PlayerEffect.playersInScope (Plane.rangePerspective source controller gs) (Just controller) gs (ChoosePlayer.scope choice)))
  Monad.forM_ chosenPlayer $ \pid -> State.modify' (Common.bindPlayerSlot resolving slot (Set.singleton pid))

-- ChoosePlayer's twin with the decision replaced by randomness (Ruhan of the
-- Fomori's "choose an opponent at random", Strax, Sontaran Nurse's "choose a
-- player at random"): the same fold, the same bind, and the same CR 608.2d
-- moment -- only the question changes. CR 701.9b's distinction between "at
-- random" and "the player chooses" is why it is a separate opcode and a
-- separate prompt.
--
-- WHICH players are offered is the payload's PlayerScope, read through the
-- same PlayerEffect.playersInScope the deciding twin above reads, against CR
-- 109.5's "you" -- so the offer can hold
-- the resolving controller (PlayerScope.Related AnyPlayer) and this arm still
-- classifies rather than naming a card. Nobody in scope binds nothing (CR 101.3); CR 102.2 leaves
-- PlayerScope.Related Opponent nothing to pick at two seats.
--
-- ONE prompt where the deciding twin picks between two: Prompt.RandomPlayer
-- carries no Decider, so there is no promise about the chooser for a second
-- constructor to make.
--
-- Through Game.drawAmong: the question goes to the INTERPRETER, and the engine
-- does not roll and no player picks.
choosePlayerAtRandom :: ObjectId -> ObjectId -> PlayerId -> ChoosePlayerAtRandom.ChoosePlayerAtRandom -> Game ()
choosePlayerAtRandom resolving source controller choice = do
  gs <- State.get
  let slot = ChoosePlayerAtRandom.slot choice
      candidates = Maybe.fromMaybe [] (PlayerEffect.playersInScope (Plane.rangePerspective source controller gs) (Just controller) gs (ChoosePlayerAtRandom.scope choice))
  chosenPlayer <- Game.drawAmong Prompt.RandomPlayer candidates
  Monad.forM_ chosenPlayer $ \pid -> State.modify' (Common.bindPlayerSlot resolving slot (Set.singleton pid))

-- CR 608.2d: the seat the payload names picks any number of the matching
-- permanents -- Archfiend of Depravity's "that player chooses up to two
-- creatures they control" -- and the pick is bound as a group for a later
-- instruction to act on, through Filter.IsBound ("the rest") or InSlot.
-- chosenPermanents is ObjectRef.ChosenPermanents' ask, CR 800.4g included; a
-- ref naming nobody asks nobody and binds nothing (CR 101.3). Proved by
-- Parun.BoardEffectSpec's "CR 608.2d that player chooses the two they keep and
-- sacrifices the rest".
--
-- CR 700.3 where a pile chooser is named: the pick is one pile and the rest of
-- the matching permanents the other, and the pile chooser's pile is what is
-- bound -- Stand or Fall, through Common.takePile. Proved by the combat-effect
-- scenarios "CR 700.3 / 509.1b Stand or Fall" and "CR 700.3 / 802.2 Stand or
-- Fall at three seats".
choosePermanents :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ChoosePermanents.ChoosePermanents -> Game ()
choosePermanents resolving source controller legal (ChoosePermanents.MkChoosePermanents choice slot pileChooser) = do
  picked <- case pileChooser of
    Nothing -> Common.chosenPermanents AnyNumberOf.Permanents legal resolving controller source choice
    Just chooserRef -> do
      gs <- State.get
      let matching = chosenCandidates legal resolving controller source gs choice
      split <- case matching of
        [_] -> pure matching
        _ -> Common.chosenPermanents AnyNumberOf.IntoPile legal resolving controller source choice
      Common.takePile resolving source controller legal chooserRef matching split
  Monad.unless (null picked) (State.modify' (Common.bindObjectsSlot resolving slot (Seq.fromList picked)))

-- CR 702.158d: "choose one of the three sector designations, then perform
-- that action on each creature with that designation". The resolving
-- controller is asked -- three candidates, so never elided -- and the
-- permanents in the chosen sector are bound as a group, ChoosePermanents'
-- posture, for the following instruction's Filter.IsBound. An empty sector
-- binds nothing, so that instruction acts on nothing (CR 101.3).
chooseSector :: ObjectId -> ObjectId -> PlayerId -> SlotName -> Game ()
chooseSector resolving source controller slot = do
  picked <- Game.chooseAmong (\decider who -> Prompt.ChooseDesignation decider who source) controller (NonEmpty.toList Sector.sectors)
  Monad.forM_ picked $ \sector -> do
    gs <- State.get
    let inSector oid = maybe False (Set.member sector . Object.designations) (Game.lookupObject oid gs)
        members = filter inSector (Set.toList (GameState.battlefield gs))
    Monad.unless (null members) (State.modify' (Common.bindObjectsSlot resolving slot (Seq.fromList members)))

-- CR 706.1: roll a die of the stated kind, and bind CR 706.4's result at the
-- slot for a later effect of this same resolution to read (Ancient Copper
-- Dragon's "roll a d20. You create a number of Treasure tokens equal to the
-- result").
--
-- Bound on `source`, which is bindAmountSlot's own contract (CR 608.2h aims an
-- amount read at the effect's source) and the holder Destroy's "destroyed this
-- way" tally already uses. Unobservable on THIS producer, and the DiceSpec case
-- below does not prove it: Quantity.InSlot reads the source first and then the
-- object CR 603.3 put on the stack, which for a triggered ability is
-- `resolving`, so either holder answers here. Consistency, not a behaviour.
--
-- Game.ask and not Game.choose, since a die result is not CR 104.4b's optional
-- action: nobody is deciding, so there is nothing to usurp. The question goes
-- to the INTERPRETER -- the engine never rolls. Filtered rather than trusted,
-- against CR 706.1a's outcomes "numbered from 1 to N", BOTH ends included, so
-- an answer outside the range leaves the floor standing rather than a value no
-- die could show; the instruction is mandatory, so there is no third option.
--
-- CR 706.2: the natural result is the face, and the instruction's own modifier
-- is added to it to give the RESULT, which is what this binds (Diviner's
-- Portent). ORDER IS LOAD-BEARING: CR 706.1a bounds the face at 1..N and no
-- rule bounds the sum, so the filter runs on the face and the modifier is added
-- after -- a d20 answered 20 with a modifier of 5 is a result of 25, past the
-- die's own top face. CR 107.1b for a sum a negative modifier drove below zero.
--
-- CR 706.2b's two steps are taken in the rule's order: `rerolling` below,
-- per die on its natural result, and then `adjusting`, once every die is up.
--
-- CR 706.1's roll is also the PlayerAction.RollDice TriggerCondition.PlayerActs watches
-- (Feywild Trickster). Recorded under each ROLLER, not `source`: rule 706.1's
-- instruction is aimed at a PLAYER, RollDie's `roller`, read against CR
-- 109.5's "you" -- the resolving controller. Several rollers throw in APNAP
-- order (CR 101.4), each through throwDice as the player CR 706.2b's pick and
-- CR 706.2a's modifiers belong to, and each chooses their own CR 706.4 result.
--
-- One writer per road: Prompt.RollDie is asked from throwSettled alone, and
-- this arm records the roll it throws -- a reroll records its own, see
-- `rethrow`.
--
-- Recorded AFTER the binding, so a trigger placed by CR 603.3 sees the same
-- state a later effect of this resolution would. Nothing observes the order --
-- the trigger goes on the stack only once this resolution finishes. Where
-- several roll, `slot` binds the highest result any of them used and
-- `highest` every player who had it, ties included (Chaos Dragon).
--
-- ONE ENTRY PER INSTRUCTION, however many dice CR 706.1's count named, where
-- FlipCoin below records one per coin: the condition reading this event is
-- Feywild Trickster's "whenever you roll one or more dice", which the printed
-- words scope to the instruction rather than to the die. An instruction that
-- rolls no dice at all records nothing, having rolled none; a reroll is a
-- roll of its own and records its own.
rollDieArm :: (Game Result -> PlayerId -> Natural -> Natural -> Game Integer -> Game ([Natural], [PlayerId], [Natural])) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> RollDie.RollDie -> Game ()
rollDieArm throwDice runSubgame resolving source controller legal rollDie = do
  before <- State.get
  let sides = RollDie.sides rollDie
      -- How many dice the instruction NAMES -- what a CR 614.1a row is then
      -- offered below, and not necessarily how many are thrown. Read ONCE
      -- before the first of them, FlipCoin's count below and for its reason:
      -- the number is part of the instruction, and re-reading it per die would
      -- let a count over the board throw a different number than the
      -- instruction named. CR 107.2's
      -- posture for a quantity that cannot be evaluated: no dice at all.
      named =
        Integer.toNaturalSaturating
          ( Maybe.fromMaybe
              0
              ( Quantity.evaluateFor
                  (effectViewOf source legal before)
                  (effectContext before resolving controller source legal (slotBindings resolving before))
                  before
                  resolving
                  source
                  (RollDie.count rollDie)
              )
          )
  let perDie :: Game Integer
      perDie = do
        gs <- State.get
        let viewOf = effectViewOf source legal gs
            context = effectContext gs resolving controller source legal (slotBindings resolving gs)
        -- CR 706.2, read AFTER the roll as the rule words it, and per die:
        -- the rule adds the modifier to the natural result of a roll, so a
        -- count above one adds it to each. CR 107.2's posture for a modifier
        -- that cannot be evaluated: no modifier at all.
        pure $ case RollDie.modifier rollDie of
          Nothing -> 0
          Just quantity -> Maybe.fromMaybe 0 (Quantity.evaluateFor viewOf context gs resolving source quantity)
      -- CR 801.10's table: a roller is in the controller's range, still
      -- playing, and in the instruction's scope.
      rollers = filter (\pid -> Game.inRangeOf controller pid before && PlayerEffect.inScope pid controller before (RollDie.roller rollDie)) (Game.apnapOrder before)
  rolled <- Monad.forM rollers $ \roller -> do
    (results, throwers, thrown) <- throwDice runSubgame roller sides named perDie
    used <- case (RollDie.store rollDie, RollDie.reading rollDie) of
      -- CR 706.8a: a storing instruction keeps every result rather than
      -- using one, so CR 706.4's reading is never asked.
      (Just _, _) -> pure Nothing
      -- CR 706.4's total: every result read at once, so there is nothing to
      -- choose, and the total of no dice is zero rather than unbound.
      (Nothing, DiceReading.Total) -> pure (Just (sum results))
      -- CR 706.4's text reading each of two results on its own: no choice
      -- (Celebr-8000 prints none), the first die rolled at `slot` and the
      -- second at `other`. The card's readers are symmetric in the two, so
      -- which die lands where is unobservable. Any other number of results
      -- leaves both unbound, `other`'s posture below.
      (Nothing, DiceReading.Both) -> case results of
        [first, second] -> do
          Foldable.for_ (RollDie.other rollDie) $ \other -> State.modify' (Common.bindAmountSlot resolving source other second)
          pure (Just first)
        _ -> pure Nothing
      (Nothing, DiceReading.ChooseOne) -> Monad.forM (NonEmpty.nonEmpty results) $ \offered -> do
        gs <- State.get
        -- CR 706.4: WHICH result the instruction uses, where it threw more
        -- than one ("roll two d6 and choose one result"). A choice and not a
        -- roll, so it goes through Game.choose and CR 723.5's controller may
        -- make it. Elided where every result is the same number: both
        -- bindings below come out the same whichever die is named, so no
        -- board can tell the answers apart. FILTERED, NOT TRUSTED, the
        -- ChooseBolster posture: an index past the end takes the first die
        -- rolled.
        index <-
          if all (== NonEmpty.head offered) (NonEmpty.tail offered)
            then pure 0
            else do
              answer <- Game.choose (Prompt.ChooseDieResult (Decide.deciderFor roller gs) roller (Just resolving) offered)
              pure (if answer < List.genericLength results then answer else 0)
        -- CR 706.4's "the other result", off the same throw rather than
        -- re-derived from the count, FlipCoin's `misses` below and for its
        -- reason. Only a two-die instruction has an "other": at any other
        -- count what is left is not one number, and the slot stays unbound
        -- rather than guessing which of them the card meant. Parun.CardSpec's
        -- lint keeps data/cards/ to counts this can answer for, and to one
        -- roller.
        Foldable.for_ (RollDie.other rollDie) $ \other ->
          case fmap snd (filter (\(i, _) -> i /= index) (zip [0 ..] results)) of
            [rest] -> State.modify' (Common.bindAmountSlot resolving source other rest)
            _ -> pure ()
        pure (Replacement.at results index (NonEmpty.head offered))
    pure (roller, used, (throwers, thrown), results)
  let top = fmap maximum (NonEmpty.nonEmpty [n | (_, Just n, _, _) <- rolled])
  Foldable.for_ top $ \n -> do
    State.modify' (Common.bindAmountSlot resolving source (RollDie.slot rollDie) n)
    Foldable.for_ (RollDie.highest rollDie) $ \slot ->
      State.modify' (Common.bindPlayerSlot resolving slot (Set.fromList [roller | (roller, Just m, _, _) <- rolled, m == n]))
  Foldable.for_ rolled $ \(roller, _, (throwers, thrown), _) ->
    Monad.unless (null thrown) (Common.recordRoll roller throwers thrown)
  -- CR 706.8a: every kept result, noted with its kind of die, on the slot's
  -- permanent.
  Foldable.for_ (RollDie.store rollDie >>= \slot -> legalOne slot legal >>= Recipient.objectOf) $ \target -> do
    acquisition <- State.gets (\g -> Game.readingAcquisition resolving source g target)
    State.modify' (Common.storeOn acquisition target sides (foldMap (\(_, _, _, results) -> results) rolled))

-- CR 706.2b's reroll, asked for by the ability Goblin Bookie activates inside
-- throwDice's window, through GameState.rerollRequested. The die is thrown
-- again once the ability is done, by throwSettled's `rethrow`, as the
-- activating player's CR 706.1 roll. No window open, no die to reroll, and
-- nothing happens.
reroll :: Game ()
reroll = State.modify' (\g -> if Maybe.isJust (GameState.rollingDie g) then g {GameState.rerollRequested = True} else g)

-- CR 706.8b: the controller chooses which of the slot's stored results to
-- reroll, rolls one die of each noted kind per result through throwDice --
-- so CR 706.2's modifiers and CR 614.1a's replacements reach it, and each
-- kind's throw records CR 706.1's event -- and the new results replace the
-- old.
--
-- CR 607.5 / 706.8c: only the results the resolving ability's own pair
-- stored, so a copy's reroll finds none its printed pair stored.
rerollStoredResults :: (Game Result -> PlayerId -> Natural -> Natural -> Game Integer -> Game ([Natural], [PlayerId], [Natural])) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> SlotName -> Game ()
rerollStoredResults throwDice runSubgame resolving source controller legal slot = Foldable.for_ (legalOne slot legal >>= Recipient.objectOf) $ \target -> do
  gs <- State.get
  let acquisition = Game.readingAcquisition resolving source gs target
      stored = foldMap (Game.storedResultsUnder acquisition) (Game.lookupObject target gs)
  Monad.unless (Map.null stored) $ do
    answer <- Game.choose (Prompt.ChooseStoredRerolls (Decide.deciderFor controller gs) controller target stored)
    -- FILTERED, NOT TRUSTED: each count clamped to what the object holds.
    let rerolled = Map.filter (> 0) (Map.intersectionWith min answer stored)
        kinds = Map.fromListWith (+) [(StoredResult.sides result, n) | (result, n) <- Map.toList rerolled]
    thrown <- Monad.forM (Map.toList kinds) $ \(dieSides, n) -> do
      (results, throwers, rolled) <- throwDice runSubgame controller dieSides n (pure 0)
      Monad.unless (null rolled) (Common.recordRoll controller throwers rolled)
      pure (dieSides, results)
    -- Swapped only once every die is up, in the rule's order.
    let unstore o = o {Object.storedResults = Map.filter (not . Map.null) (Map.adjust (\held -> Map.differenceWith (\have gone -> if have > gone then Just (have - gone) else Nothing) held rerolled) acquisition (Object.storedResults o))}
    State.modify' (\g -> g {GameState.objects = Map.adjust unstore target (GameState.objects g)})
    Foldable.for_ thrown $ \(dieSides, results) -> State.modify' (Common.storeOn acquisition target dieSides results)

-- CR 705.1's flip, in RollDie's holder and for its reason: bindAmountSlot's
-- `source` is the resolving object, and on a SPELL -- which Winter Sky is --
-- `source` and `resolving` are the same object, so the ambiguity the arm above
-- documents does not arise there. A triggered ability that flipped would land
-- on that arm's reasoning instead, which says either holder answers.
--
-- ONE INSTRUCTION, however many coins (CR 705.1, CR 705.2): neither rule scopes
-- itself to a single coin, and Flock of Rabid Sheep's "flip X coins" is one
-- instruction. The slot binds a TALLY over them -- how many flips the flipper
-- won, or how many coins came up heads, per Parun.Types.CoinReading -- which on
-- the one-coin instruction Winter Sky prints is the 1 or 0 it always was.
--
-- No filtering back, unlike RollDie: CR 705.1's coin has exactly two sides and
-- Parun.Types.CoinFace has exactly two constructors, so every answer is in
-- range.
--
-- The flippers are the seats `flipper` names in APNAP order (CR 101.4) --
-- `controller`, CR 109.5's "you", for every printing but Mana Clash's target
-- opponent -- and CR 705.2's last sentence keeps everyone else out of each
-- flip, so each flipper calls their own coin. The tallies sum over them.
--
-- CR 705.1's flip is also the event TriggerCondition's PlayerWinsCoinFlip and
-- PlayerLosesCoinFlip watch (Tavern Scoundrel, Karplusan Minotaur), recorded
-- under the flipper: the instruction is aimed at that player, and CR 705.2's
-- last sentence keeps every other seat out of it. EVERY coin is recorded, won or lost -- Parun.Types.CoinFlipped
-- says why the outcome is a field rather than the presence of an entry -- and
-- one entry per coin, since the event is the log of flips rather than of
-- instructions.
--
-- THREE WRITERS, three roads. Parun.Engine.Event's ChoiceByCoinFlip arm is the
-- flip made as a permanent enters (Molten Sentry) and Parun.Engine.Cost's
-- CostComponent.FlipCoin arm is the flip a COST names (Karplusan Minotaur),
-- each recording its own CoinFlipped. Every road that flips records, which is
-- what keeps this event the log of CR 705.1 flips rather than of one opcode.
--
-- Recorded per coin and so BEFORE the binding, where the roll above records
-- after it: the tally is not settled until the last coin, and nothing observes
-- the order -- a trigger CR 603.3 places goes on the stack only once this
-- resolution finishes.
--
-- CR 705.3's second clause is the `stated` half: an effect may state that this
-- player WINS the flip, and then the call and the face are both ignored
-- ("ignore the actual results of that flip and use the indicated results
-- instead"). Its first clause -- the stated FACE -- is applied inside
-- Parun.Engine.Event.flipOneCoin, before the comparison here sees the face at
-- all, which is why a statement of heads alone still loses this flip against a
-- call of tails.
flipCoinArm :: (Game Result -> Throw.Throw -> Game [Natural]) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> FlipCoin.FlipCoin -> Game ()
flipCoinArm throwForCoin runSubgame resolving source controller legal flipCoin = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- How many coins the instruction flips, read ONCE before the first of
      -- them: the number is part of the instruction, and re-reading it per coin
      -- would let a count over the board flip a different number than the
      -- instruction named. CR 107.2's posture for a quantity that cannot be
      -- evaluated: no coins at all.
      coins = Integer.toNaturalSaturating (Maybe.fromMaybe 0 (Quantity.evaluateFor viewOf context gs resolving source (FlipCoin.count flipCoin)))
      flippers = Common.apnapPlayersOf (FlipCoin.flipper flipCoin) legal resolving source controller gs
  -- CR 705.3's statements, read once per flipper for the whole instruction
  -- rather than per coin -- Parun.Engine.Coin.statementsFor says why Edgar's
  -- "the first time you flip one or more coins each turn" makes that the
  -- difference.
  let flipsOf flipper = do
        statements <- Coin.statementsFor (Just flipper)
        Foldable.foldlM (flipOnce flipper statements) (0 :: Natural) [1 .. coins]
      flipOnce flipper statements acc _ = do
        hit <- case FlipCoin.reading flipCoin of
          -- CR 705.2's win/lose flip, whole: the call, the flip, the
          -- comparison and the CR 705.1 event all belong to
          -- Event.flipWinLoseCoin, which is also the road a COST'S flip takes.
          -- That module's haddock argues the order of the two questions, and
          -- Parun.CoinSpec's "only the flipping player calls" proves it by what
          -- the engine ASKED rather than by anything the board shows.
          CoinReading.Wins -> Event.flipWinLoseCoin (Just (throwForCoin runSubgame)) flipper statements
          -- CR 705.2's first sentence: the effect cares only about the face, so
          -- no Prompt.CallCoin is asked -- "no player wins or loses a coin flip
          -- for this kind of effect", so there is no call to make and nothing
          -- for a CR 723 controller to usurp. The flip is recorded with no
          -- outcome, which is what keeps rule 705.2's first sentence honest
          -- against TriggerCondition's two coin-flip conditions, neither of
          -- which matches an outcome of Nothing; see
          -- Parun.Types.CoinFlipped. CR 705.3's second clause is the exception
          -- the rule itself names, Parun.Engine.Event's entry road verbatim: an
          -- effect may state that a player WINS a flip that would ordinarily
          -- have no winner.
          --
          -- Where Pokey, the Scallywagg rolled instead, the face the roll is
          -- read as counts and no CR 705.1 event is recorded; where it then
          -- flipped a coin for that d20, the coin is called
          -- (Event.settleCoins).
          CoinReading.Heads -> do
            (face, _) <- Event.flipOneCoin (Just (throwForCoin runSubgame)) (Just flipper) Nothing statements
            pure (face == Just CoinFace.Heads)
        pure (if hit then acc + 1 else acc)
  -- Bound AFTER every coin, since CR 705.2 asks how many of the flips matched
  -- and one instruction's flips are all of them.
  tally <- sum <$> traverse flipsOf flippers
  State.modify' (Common.bindAmountSlot resolving source (FlipCoin.slot flipCoin) tally)
  -- The flips that did NOT match, off the same coins. WHICH sentence of CR
  -- 705.2 that is depends on the reading: for a win/lose flip it is
  -- "otherwise, the player loses the flip", and for one that cares only about
  -- the face it is the first sentence's tails, where no player wins or loses
  -- at all. Either way it is the complement of the tally above, so the two are
  -- bound from one set of flips rather than one being re-derived from the
  -- count. Parun.CoinSpec's Mutalith Vortex Beast group proves a lost flip
  -- reaches the loser and a won one does not.
  Foldable.for_ (FlipCoin.misses flipCoin) $ \misses ->
    State.modify' (Common.bindAmountSlot resolving source misses (coins * List.genericLength flippers - tally))

controlPlayerNextTurn :: PlayerId -> Map.Map SlotName (Set Recipient) -> SlotName -> Game ()
controlPlayerNextTurn controller legal slot =
  State.modify' $ \gs ->
    case legalOne slot legal of
      Just (Recipient.ToPlayer target) ->
        -- CR 723.1: schedule control of `target` by this ability's controller
        -- (CR 723.5). Map.insert overwrites a prior pending control (CR 723.1a),
        -- and the row is stamped NOW, as the effect is created.
        let (stamp, stamped) = Game.freshTimestamp gs
            row =
              PlayerControl.MkPlayerControl
                { PlayerControl.decider = Decider.MkDecider controller,
                  PlayerControl.duration = ControlDuration.UntilTurnEnds,
                  -- CR 723.7: Mindslaver prints no restriction.
                  PlayerControl.manaFromLandsOnly = False,
                  PlayerControl.timestamp = stamp
                }
            schedule g pid = g {GameState.pendingControl = Map.insert pid row (GameState.pendingControl g)}
         in List.foldl' schedule stamped (Common.controlledTeam controller target stamped)
      -- Not a player recipient or an illegal slot (CR 608.2b): no-op.
      _ -> gs

-- CR 723.2: control that takes hold NOW and lapses when this object finishes
-- resolving, which Parun.Engine.Stack.resolveTopWith is what performs -- the
-- one place that knows a resolution has ended.
--
-- Written into the live GameState.control rather than scheduled, which is the
-- whole difference from the arm above: rule 723.1b's control waits for a turn,
-- and this one is spent inside the resolution that installed it. CR 723.1a is
-- pushControl's, not Map.insert's -- a live control on the same player is
-- layered under rather than destroyed.
controlPlayerThisResolution :: PlayerId -> Map.Map SlotName (Set Recipient) -> ControlPlayer.ControlPlayer -> Game ()
controlPlayerThisResolution controller legal (ControlPlayer.MkControlPlayer slot landsOnly) =
  State.modify' $ \gs ->
    case legalOne slot legal of
      Just (Recipient.ToPlayer target) ->
        let (stamp, stamped) = Game.freshTimestamp gs
            row =
              PlayerControl.MkPlayerControl
                { PlayerControl.decider = Decider.MkDecider controller,
                  PlayerControl.duration = ControlDuration.UntilResolutionEnds,
                  PlayerControl.manaFromLandsOnly = landsOnly,
                  PlayerControl.timestamp = stamp
                }
         in List.foldl' (\g pid -> Common.pushControl pid row g) stamped (Common.controlledTeam controller target stamped)
      -- Not a player recipient or an illegal slot (CR 608.2b): no-op.
      _ -> gs

destroy :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Destroy.Destroy -> Game ()
destroy resolving source controller legal chosen (Destroy.MkDestroy ref regenerability mSlot mBuried mPermanents) = do
  -- CR 701.8: destroy them through the single funnel -- indestructible (CR
  -- 702.12b) and regeneration (CR 701.19a) are Event.destroy's to decide, and
  -- the card's own CR 701.19c rider rides along. ONE batch, not one call per
  -- victim (CR 608.2f). An illegal slot (CR 608.2b), a non-object recipient, or
  -- a set that matched nothing all arrive here as the empty list. Through
  -- askingObjects, so Capricious Efreet's "one of them at random" is drawn.
  victims <- Common.askingObjects resolving source controller legal chosen ref
  destroyed <- Event.destroyReturning regenerability victims
  -- CR 701.8b: "destroyed this way" is what the funnel DESTROYED, never what
  -- the sweep named. Bound onto this effect's SOURCE so a later effect of the
  -- same resolution reads it as Quantity.InSlot, through live GameState rather
  -- than through `chosen`, which carries recipients rather than amounts. Bound
  -- even when nothing was destroyed: zero is an answer, where an unbound slot
  -- would make the rider's quantity unevaluable instead.
  Monad.forM_ mSlot $ \slot ->
    State.modify' (Common.bindAmountSlot resolving source slot (Natural.length destroyed))
  -- The other reading of the same printed phrase: the CARDS "put into a
  -- graveyard this way", for Come Back Wrong's "return it to the battlefield"
  -- to name. Bound onto `resolving` and as a GROUP, which is where and how
  -- MoveToZone binds its own arrivals (CR 400.7j) and the only shape every
  -- reader of a slot a destruction defines can see: slotGroup reads live
  -- GameState unconditionally, where a single binding would have to survive
  -- `chosen`.
  --
  -- Two filters, both read off the board AFTER the funnel rather than off the
  -- funnel's answer, because the answer names the incarnation and not where it
  -- ended up:
  --
  --   * in a GRAVEYARD. A CR 614 replacement may send the destroyed permanent
  --     to exile instead (Rest in Peace), and then nothing was put into a
  --     graveyard this way. A cancelled move (CR 616.1) has no incarnation at
  --     all and is already Nothing.
  --   * a CARD. CR 111.6 says a token is not a card, and every printed reader
  --     of this slot says "card" -- "if a creature CARD is put into a graveyard
  --     this way", "return each CARD put into a graveyard this way". A second
  --     rule would refuse the same token one step later -- CR 111.8, which
  --     Parun.Engine.Event's zone-change funnel states -- so this filter is what
  --     the CARD says rather than the only thing standing in the way.
  --
  -- Nothing is bound when nothing qualifies, MoveToZone's rule: no slot names
  -- an empty set, so the later clause finds an unbound slot and does nothing --
  -- which is exactly what "IF a creature card is put into a graveyard this way"
  -- asks for.
  --
  -- EVERY arrival of each destruction, not just the first: CR 712.21c gives an
  -- effect that finds what a melded permanent becomes both cards, and CR
  -- 712.21e counts a melded permanent as two CARDS put into a graveyard where
  -- the amount slot above counts it as one OBJECT destroyed.
  Monad.forM_ mBuried $ \slot -> do
    after <- State.get
    let buriedCards = concatMap (filter (\oid -> Common.isCardInAGraveyard oid after) . Foldable.toList . snd) destroyed
    Monad.unless (null buriedCards) (State.modify' (Common.bindObjectsSlot resolving slot (Seq.fromList buriedCards)))
  -- The THIRD reading, and the only one that keeps a controller: the PERMANENTS
  -- CR 701.8 destroyed, under the ids they held on the battlefield, for
  -- Effect.ForEach to walk one at a time -- Rampage of the Clans' "for each
  -- permanent destroyed this way, its controller creates a 3/3 green Centaur
  -- creature token". `fst`, not `snd`: the incarnation the graveyard move
  -- minted is a different object (CR 400.7), and a card in a graveyard has no
  -- controller (CR 108.4) so CR 108.4a would answer with its OWNER -- a
  -- different player for anything that was stolen. Only these ids answer "its
  -- controller", through CR 608.2h's last known information.
  --
  -- The funnel's own answer and not the sweep (CR 701.8b): an indestructible
  -- permanent (CR 702.12b) and a regenerated one (CR 701.8c) were not
  -- destroyed, so neither is walked. No board filter of `buried`'s kind: what
  -- the rider asks about is the destruction, not where the remains landed, so a
  -- CR 614 replacement sending the card to exile changes nothing here.
  --
  -- Bound onto `resolving` as a GROUP, `buried`'s shape and for its reason:
  -- slotGroup reads live GameState unconditionally. Nothing is bound when
  -- nothing was destroyed, so the loop finds an unbound slot and runs no
  -- iterations (CR 101.3).
  Monad.forM_ mPermanents $ \slot ->
    Monad.unless (null destroyed) (State.modify' (Common.bindObjectsSlot resolving slot (Seq.fromList (fmap fst destroyed))))

sacrifice :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> SacrificeEffect.SacrificeEffect -> Game ()
sacrifice resolving source controller legal chosen (SacrificeEffect.MkSacrificeEffect ref sacrificer mSacrificed) = do
  -- CR 701.21 through the single funnel, which is NOT Event.destroy (CR
  -- 701.21a): a sacrifice is not a destruction, so indestructible (CR 702.12b)
  -- and a regeneration shield leave it alone.
  --
  -- The victims come from askingObjects, objectRefObjects' sweep plus
  -- CR 608.2d's asked ref: Golgothian Sylex's EachMatching sweeps the
  -- battlefield, and God-Eternal Bontu's ChosenPermanents is asked here.
  -- Its InSlot arm keeps what a bare SlotName did: a slot a Create bound to a
  -- GROUP names every token at once, in mint order, ahead of the target read
  -- and owing CR 608.2b nothing; an illegal slot (CR 608.2b) and a player
  -- recipient both arrive here as the empty list. CR 603.7c's zone check
  -- applies per MEMBER rather than to the whole word: a member that is gone is
  -- simply not affected, and the rest still are.
  --
  -- ONE event over the whole sweep, not one call per victim: CR 608.2f makes
  -- an action an instruction takes on multiple objects simultaneous, so every
  -- member's CR 616.1 loop reads the board the batch began on -- All Is Dust
  -- sacrificing Rest in Peace beside another coloured permanent exiles both.
  -- Parun.EventSpec's All Is Dust case is the proof.
  victims <- Common.askingObjects resolving source controller legal chosen ref
  gs <- State.get
  Event.sacrificeAll (Maybe.mapMaybe (Common.sacrificerFor sacrificer controller gs) victims)
  -- "That many" is what the funnel SACRIFICED, never what the sweep named: a
  -- permanent it refused (CR 701.21a's control clause, CR 101.2's "can't") is
  -- not counted. Read off the GameEvent.PermanentSacrificed entries the batch
  -- appended, which the funnel records before any CR 614 redirection, so a
  -- permanent Rest in Peace exiles instead still counts. Bound even at zero,
  -- the Destroy arm's `slot` and for its reason.
  Monad.forM_ mSacrificed $ \slot -> do
    after <- State.get
    let isSacrifice logged = case LoggedEvent.event logged of
          GameEvent.PermanentSacrificed _ -> True
          _ -> False
        count = Natural.length (Seq.filter isSacrifice (Seq.drop (Seq.length (GameState.events gs)) (GameState.events after)))
    State.modify' (Common.bindAmountSlot resolving source slot count)

turnFaceDown :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> TurnFaceDown.TurnFaceDown (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()
turnFaceDown resolving source controller legal (TurnFaceDown.MkTurnFaceDown ref listed) = do
  -- CR 708.2: ONE assignment to Object.facing per victim is the whole effect.
  -- What each permanent becomes is the list the effect carries (CR 708.2a's
  -- 2/2 when it lists nothing); the rule calls those copiable values, so this
  -- is a copiable swap rather than a CR 613 layer, performed by Game.faceOf.
  -- FaceDownReason.TurnedFaceDown is CR 708.6's other half: it closes CR
  -- 701.40b's turn-face-up procedure and leaves CR 702.37e's open. No CR 400.7
  -- incarnation is minted, so the object id, marked damage, counters,
  -- attachments and statuses all ride through -- the mirror of
  -- Event.performTurnFaceUp.
  --
  -- The TIMESTAMP does NOT ride through, and it is the one thing on that list
  -- that does not: CR 613.7f gives a permanent a new one each time it turns
  -- face down. Written by Game.turnFacing, the primitive the turn-face-up road
  -- shares, so one rule has one writer.
  --
  -- CR 708.2b is the guard below: an effect that LISTS its own values would
  -- otherwise overwrite the list already there, and a permanent it spares
  -- records no PermanentAction.TurnFaceDown either. Parun.FaceDownSpec's "CR 708.2b
  -- Synthetic Veiled Witness draws nothing off a permanent already face down"
  -- proves it.
  --
  -- The victims are enumerated ONCE (CR 608.2f), as RemoveFromCombat's fold
  -- below does; an illegal slot (CR 608.2b), a player recipient and an empty
  -- match all turn nothing over. CR 608.2f's own secondary sentence never
  -- engages -- turning A face down cannot change whether B may be, so the
  -- turnings are processed simultaneously -- and what IS asked below is a
  -- different question: which of the simultaneous CR 613.7f stamps is earlier.
  --
  -- A permanent already face down is turned no further, and neither is one
  -- CR 712.16 / 730.2j forbids (Game.isDoubleFacedPermanent), both read off
  -- the gather's board rather than the fold's; the two agree, turning one
  -- permanent face down leaving another's facing and cards alone.
  --
  -- LEFT fold, where RemoveFromCombat's is a right one, and the stamp above is
  -- why: the fold hands out timestamps, so it must run `ordered` forwards for
  -- the earlier stamp to go to the permanent CR 613.7m put first.
  gs0 <- State.get
  let alreadyDown target = maybe False (Facing.isFaceDown . Object.facing) (Map.lookup target (GameState.objects gs0))
      turnable target = not (alreadyDown target || Game.isDoubleFacedPermanent target gs0)
      faceUp = filter turnable (objectRefObjects legal resolving controller source gs0 ref)
  ordered <- Restamp.order faceUp
  State.modify'
    ( \gs ->
        List.foldl'
          (flip (Game.turnFacing (Facing.FaceDown FaceDownState.MkFaceDownState {FaceDownState.reason = FaceDownReason.TurnedFaceDown, FaceDownState.listed = listed, FaceDownState.turnsUpBefore = Set.empty})))
          gs
          ordered
    )
  -- CR 701.27b: one event per permanent that actually turned, after the writes,
  -- so a trigger's Filter reads the face-down permanent (CR 603.10).
  Monad.mapM_ (State.modify' . Event.recordEvent . GameEvent.PermanentActed . PermanentActed.MkPermanentActed PermanentAction.TurnFaceDown) ordered
  -- CR 611.2a: "until this creature is turned face down" (Vesuvan
  -- Shapeshifter) ends here, for each permanent that actually turned. This
  -- arm is the only road that turns a permanent face down.
  Monad.mapM_ (State.modify' . Expiry.sweep . Expiry.TurnedFaceDown) ordered

-- CR 708 through Event.turnFaceUpByEffect, the funnel CR 116.2b's special
-- action shares: this arm decides only WHICH permanent, never what turning it
-- over does. CR 701.40g lives inside that funnel and so applies here without
-- this arm knowing the rule exists.
--
-- Read as ObjectRef.InSlot reads it, so a slot an earlier clause CHOSE into
-- (Bustle's "you may turn a creature you control face up", CR 608.2d) is
-- reached as a target slot is; an illegal target (CR 608.2b) turns nothing.
turnFaceUp :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> SlotName -> Game ()
turnFaceUp resolving source controller legal slot = do
  gs <- State.get
  Monad.mapM_ Event.turnFaceUpByEffect (objectRefObjects legal resolving controller source gs (ObjectRef.InSlot slot))

removeFromCombat :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
removeFromCombat resolving source controller legal ref =
  State.modify' $ \gs ->
    -- CR 506.4: through Game.removeFromCombat, the one performer of every
    -- clause of that rule, so CR 509.1h's asymmetry comes along for free.
    -- Unprompted and undirected: the rule leaves nothing to ask.
    --
    -- The victims are enumerated ONCE (CR 608.2f), as Untap's fold above does;
    -- an illegal slot (CR 608.2b), a player recipient and an empty match all
    -- remove nothing, and a permanent already out of combat needs no guard.
    foldr Game.removeFromCombat gs (objectRefObjects legal resolving controller source gs ref)

becomesBlocked :: Map.Map SlotName (Set Recipient) -> SlotName -> Game ()
becomesBlocked legal slot =
  State.modify' $ \gs ->
    case legalOne slot legal of
      Just recipient -> case Recipient.objectOf recipient of
        Nothing -> gs -- a player recipient is not in combat
        -- CR 509.1h: through Combat.becomeBlocked, which owns every write of
        -- the blocked status and carries CR 509.3c's event. Unprompted and
        -- undirected: no creature blocks, so there is nothing to ask.
        Just target -> Combat.becomeBlocked target gs
      -- Illegal slot (CR 608.2b) or a non-object recipient: no-op.
      _ -> gs

-- CR 509.3b's third producer, through Combat.switchBlockers, which owns the
-- whole reassignment: CR 509.1b's hypothetical legality test, CR 509.1h's
-- keeping of the departed attacker's blocked status, and the events.
-- Unprompted and undirected -- General Jarkeld's sentence names every creature
-- that moves and which attacker it moves to, leaving nothing to ask.
--
-- Exactly TWO recipients, which is the slot's printed count (CR 601.2c), read
-- with legalMany as Effect.ExchangeLifeTotals' BetweenTargets is. Anything
-- else is CR 608.2b having taken one of the pair away, and the sentence has no
-- half to carry out.
switchBlockers :: Map.Map SlotName (Set Recipient) -> SlotName -> Game ()
switchBlockers legal slot =
  State.modify' $ \gs ->
    case Maybe.mapMaybe Recipient.objectOf (legalMany slot legal) of
      [firstAttacker, secondAttacker] -> Combat.switchBlockers firstAttacker secondAttacker gs
      _ -> gs

-- CR 509.3a's effect road, through Combat.exchangeBlocks, which owns the gate
-- and the events (Sorrow's Path). Both targets or nothing: CR 608.2b having
-- taken one away leaves no exchange to make.
exchangeBlocks :: Map.Map SlotName (Set Recipient) -> ExchangeBlocks.ExchangeBlocks -> Game ()
exchangeBlocks legal (ExchangeBlocks.MkExchangeBlocks firstSlot secondSlot) =
  State.modify' $ \gs ->
    case (legalOne firstSlot legal >>= Recipient.objectOf, legalOne secondSlot legal >>= Recipient.objectOf) of
      (Just firstBlocker, Just secondBlocker) -> Combat.exchangeBlocks firstBlocker secondBlocker gs
      _ -> gs
