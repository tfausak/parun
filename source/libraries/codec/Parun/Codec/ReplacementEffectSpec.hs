module Parun.Codec.ReplacementEffectSpec where

import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.ReplacementEffect as ReplacementEffect
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AsCopy as AsCopy
import qualified Parun.Types.AttachR as AttachR
import qualified Parun.Types.AttachRewrite as AttachRewrite
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.CopyDomain as CopyDomain
import qualified Parun.Types.CopyRecipient as CopyRecipient
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterPattern as CounterPattern
import qualified Parun.Types.CounterR as CounterR
import qualified Parun.Types.CounterSubject as CounterSubject
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamagePattern as DamagePattern
import qualified Parun.Types.DamageR as DamageR
import qualified Parun.Types.DamageRewrite as DamageRewrite
import qualified Parun.Types.DestructionR as DestructionR
import qualified Parun.Types.DestructionRewrite as DestructionRewrite
import qualified Parun.Types.DieRollR as DieRollR
import qualified Parun.Types.DieRollRewrite as DieRollRewrite
import qualified Parun.Types.DrawCountR as DrawCountR
import qualified Parun.Types.DrawCountRewrite as DrawCountRewrite
import qualified Parun.Types.DrawR as DrawR
import qualified Parun.Types.DrawRewrite as DrawRewrite
import qualified Parun.Types.EntryOption as EntryOption
import qualified Parun.Types.EntryR as EntryR
import qualified Parun.Types.EntryRewrite as EntryRewrite
import qualified Parun.Types.ExiledPile as ExiledPile
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.InstructionR as InstructionR
import qualified Parun.Types.InstructionRewrite as InstructionRewrite
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.LifeGainR as LifeGainR
import qualified Parun.Types.LifeGainRewrite as LifeGainRewrite
import qualified Parun.Types.LifeLossCause as LifeLossCause
import qualified Parun.Types.LifeLossPattern as LifeLossPattern
import qualified Parun.Types.LifeLossR as LifeLossR
import qualified Parun.Types.LifeLossRewrite as LifeLossRewrite
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PhasePattern as PhasePattern
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.PlaneswalkR as PlaneswalkR
import qualified Parun.Types.PlaneswalkRewrite as PlaneswalkRewrite
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerInstruction as PlayerInstruction
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.Scaling as Scaling
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TokenPattern as TokenPattern
import qualified Parun.Types.TokenR as TokenR
import qualified Parun.Types.TurnUpProcedure as TurnUpProcedure
import qualified Parun.Types.TurnUpR as TurnUpR
import qualified Parun.Types.TurnUpRewrite as TurnUpRewrite
import qualified Parun.Types.UntapR as UntapR
import qualified Parun.Types.UntapRewrite as UntapRewrite
import qualified Parun.Types.WithCounters as WithCounters
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChangePattern as ZoneChangePattern
import qualified Parun.Types.ZoneChangeR as ZoneChangeR

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s =
  let -- CR 615.5: the DamageR arm carries riders, so the codec takes the effect
      -- codec the card boundary would pass it.
      codec = ReplacementEffect.codec Card.codec (GrantedAbility.codec Card.codec) (Effect.codec Card.codec (GrantedAbility.codec Card.codec))
   in Spec.describe s "Parun.Codec.ReplacementEffect" $ do
        Spec.it s "ZoneChangeR (Rest in Peace, Anyones)" $
          Common.assertCodec
            s
            codec
            ( ReplacementEffect.ZoneChangeR
                ( ZoneChangeR.MkZoneChangeR
                    ZoneChangePattern.MkZoneChangePattern
                      { ZoneChangePattern.whenDestination = Just Zone.Graveyard,
                        ZoneChangePattern.whatObject = Filter.And [],
                        ZoneChangePattern.whoseObject = ControllerRelation.Related PlayerRelation.AnyPlayer,
                        ZoneChangePattern.whenDiscarded = Nothing,
                        ZoneChangePattern.causedBy = Nothing,
                        ZoneChangePattern.duringResolution = False
                      }
                    Zone.Exile
                    False
                    False
                    LibraryPosition.defaultValue
                    False
                )
            )
            " {\"type\":\"ZoneChangeR\",\"value\":{\"matching\":{\"whenDestination\":{\"type\":\"Graveyard\"}},\"destination\":{\"type\":\"Exile\"}}} "
        -- The relation that distinguishes this from the shape above has to survive
        -- the wire too.
        Spec.it s "ZoneChangeR (Leyline of the Void, Opponents)" $
          Common.assertCodec
            s
            codec
            ( ReplacementEffect.ZoneChangeR
                ( ZoneChangeR.MkZoneChangeR
                    ZoneChangePattern.MkZoneChangePattern
                      { ZoneChangePattern.whenDestination = Just Zone.Graveyard,
                        ZoneChangePattern.whatObject = Filter.And [],
                        ZoneChangePattern.whoseObject = ControllerRelation.Related PlayerRelation.Opponent,
                        ZoneChangePattern.whenDiscarded = Nothing,
                        ZoneChangePattern.causedBy = Nothing,
                        ZoneChangePattern.duringResolution = False
                      }
                    Zone.Exile
                    False
                    False
                    LibraryPosition.defaultValue
                    False
                )
            )
            " {\"type\":\"ZoneChangeR\",\"value\":{\"matching\":{\"whenDestination\":{\"type\":\"Graveyard\"},\"whoseObject\":{\"type\":\"Opponent\"}},\"destination\":{\"type\":\"Exile\"}}} "
        -- CR 614.1c: EntryR's pattern is a bare Filter, and "as this permanent
        -- enters" is Filter.IsSource. AsCopy pins the exception-free rewrite beside it.
        Spec.it s "EntryR (Clone, IsSource + AsCopy)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.EntryR (EntryR.MkEntryR Filter.IsSource (EntryRewrite.AsCopy (AsCopy.MkAsCopy (Filter.HasCardType CardType.Creature) [] False Seq.empty (CopyDomain.InZone Zone.Battlefield) Nothing CopyRecipient.ThisObject True))))
            " {\"type\":\"EntryR\",\"value\":{\"matching\":{\"type\":\"IsSource\"},\"rewrite\":{\"type\":\"AsCopy\",\"value\":{\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}}}} "
        -- CR 208.2b: Primal Plasma's ChoiceOf, carrying P/T and keywords.
        Spec.it s "EntryR (Primal Plasma, ChoiceOf)" $
          Common.assertCodec
            s
            codec
            ( ReplacementEffect.EntryR
                ( EntryR.MkEntryR
                    Filter.IsSource
                    ( EntryRewrite.ChoiceOf
                        [ EntryOption.MkEntryOption {EntryOption.power = 3, EntryOption.toughness = 3, EntryOption.keywords = Set.empty, EntryOption.subtypes = Set.empty},
                          EntryOption.MkEntryOption {EntryOption.power = 1, EntryOption.toughness = 6, EntryOption.keywords = Set.singleton Keyword.Defender, EntryOption.subtypes = Set.empty}
                        ]
                    )
                )
            )
            " {\"type\":\"EntryR\",\"value\":{\"matching\":{\"type\":\"IsSource\"},\"rewrite\":{\"type\":\"ChoiceOf\",\"value\":[{\"power\":3,\"toughness\":3},{\"power\":1,\"toughness\":6,\"keywords\":[{\"type\":\"Defender\"}]}]}}} "
        -- CR 614.1d / 616.1b: the other-objects form, whose Filter is a real
        -- characteristic predicate rather than an identity test.
        Spec.it s "EntryR (Gather Specimens, an opponent's creature + UnderSourceControl)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.EntryR (EntryR.MkEntryR (Filter.And [Filter.HasCardType CardType.Creature, Filter.ControlledBy PlayerRelation.Opponent]) EntryRewrite.UnderSourceControl))
            " {\"type\":\"EntryR\",\"value\":{\"matching\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"ControlledBy\",\"value\":{\"type\":\"Opponent\"}}]},\"rewrite\":{\"type\":\"UnderSourceControl\"}}} "
        -- Pattern and rewrite are both DATA, so both have to survive the trip.
        Spec.it s "DamageR (combat damage, prevented)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.DamageR (DamageR.MkDamageR DamagePattern.MkDamagePattern {DamagePattern.whichKind = Just DamageKind.Combat, DamagePattern.whatSource = Filter.And [], DamagePattern.whatRecipient = Nothing, DamagePattern.whoRecipient = Nothing, DamagePattern.whichRecipient = Nothing, DamagePattern.whichSource = Nothing, DamagePattern.boundRecipient = Nothing} DamageRewrite.PreventAll Seq.empty))
            " {\"type\":\"DamageR\",\"value\":{\"matching\":{\"whichKind\":{\"type\":\"Combat\"}},\"rewrite\":{\"type\":\"PreventAll\"}}} "
        -- CR 614.15 / 614.1a: source-scoped, any kind, and a flat instead-amount
        -- rather than a prevention.
        Spec.it s "DamageR (this source's damage, set to a flat amount)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.DamageR (DamageR.MkDamageR DamagePattern.MkDamagePattern {DamagePattern.whichKind = Nothing, DamagePattern.whatSource = Filter.IsSource, DamagePattern.whatRecipient = Nothing, DamagePattern.whoRecipient = Nothing, DamagePattern.whichRecipient = Nothing, DamagePattern.whichSource = Nothing, DamagePattern.boundRecipient = Nothing} (DamageRewrite.SetAmount 4) Seq.empty))
            " {\"type\":\"DamageR\",\"value\":{\"matching\":{\"whatSource\":{\"type\":\"IsSource\"}},\"rewrite\":{\"type\":\"SetAmount\",\"value\":4}}} "
        Spec.it s "DamageR (any source's damage, doubled)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.DamageR (DamageR.MkDamageR DamagePattern.MkDamagePattern {DamagePattern.whichKind = Nothing, DamagePattern.whatSource = Filter.And [], DamagePattern.whatRecipient = Nothing, DamagePattern.whoRecipient = Nothing, DamagePattern.whichRecipient = Nothing, DamagePattern.whichSource = Nothing, DamagePattern.boundRecipient = Nothing} (DamageRewrite.Scale (Scaling.Multiply 2)) Seq.empty))
            " {\"type\":\"DamageR\",\"value\":{\"matching\":{},\"rewrite\":{\"type\":\"Scale\",\"value\":{\"type\":\"Multiply\",\"value\":2}}}} "
        -- CR 614.8: regeneration, which names no subject of its own.
        Spec.it s "DestructionR (regenerate)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.DestructionR (DestructionR.MkDestructionR Nothing DestructionRewrite.Regenerate))
            " {\"type\":\"DestructionR\",\"value\":{\"rewrite\":{\"type\":\"Regenerate\"}}} "
        -- CR 122.1d -- engine-minted, so this is the only place its wire form is
        -- pinned whole. Bewitching Leechcraft's printed row is in
        -- Parun.Codec.UntapRSpec.
        Spec.it s "UntapR (a stun counter's replacement)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.UntapR (UntapR.MkUntapR Nothing UntapRewrite.RemoveStunCounter))
            " {\"type\":\"UntapR\",\"value\":{\"rewrite\":{\"type\":\"RemoveStunCounter\"}}} "
        -- CR 614.1a / 120.4c: Worship, the damage-scoped LifeLossR producer. The other
        -- shape -- an open cause and a scaled rewrite -- is Bloodletter of Aclazotz,
        -- whose halves round-trip in Parun.Codec.LifeLossPatternSpec and
        -- Parun.Codec.LifeLossRewriteSpec.
        Spec.it s "LifeLossR (Worship)" $
          Common.assertCodec
            s
            codec
            ( ReplacementEffect.LifeLossR
                ( LifeLossR.MkLifeLossR
                    LifeLossPattern.MkLifeLossPattern
                      { LifeLossPattern.whose = ControllerRelation.Related PlayerRelation.You,
                        LifeLossPattern.whichCause = Just LifeLossCause.ByDamage
                      }
                    (LifeLossRewrite.LeaveAtLeast 1)
                )
            )
            " {\"type\":\"LifeLossR\",\"value\":{\"matching\":{\"whose\":{\"type\":\"You\"},\"whichCause\":{\"type\":\"ByDamage\"}},\"rewrite\":{\"type\":\"LeaveAtLeast\",\"value\":1}}} "
        -- CR 614.1a / 119.10: Boon Reflection, the LifeGainR producer.
        Spec.it s "LifeGainR (Boon Reflection)" $
          Common.assertCodec
            s
            codec
            ( ReplacementEffect.LifeGainR
                ( LifeGainR.MkLifeGainR
                    (ControllerRelation.Related PlayerRelation.You)
                    (LifeGainRewrite.Scaled (Scaling.Multiply 2))
                )
            )
            " {\"type\":\"LifeGainR\",\"value\":{\"whose\":{\"type\":\"You\"},\"rewrite\":{\"type\":\"Scaled\",\"value\":{\"type\":\"Multiply\",\"value\":2}}}} "
        -- CR 614.11 / 121.6: Words of Worship, the GainLife DrawR producer.
        Spec.it s "DrawR (Words of Worship)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.DrawR (DrawR.MkDrawR (ControllerRelation.Related PlayerRelation.You) (DrawRewrite.GainLife 5)))
            " {\"type\":\"DrawR\",\"value\":{\"whose\":{\"type\":\"You\"},\"rewrite\":{\"type\":\"GainLife\",\"value\":5}}} "
        -- CR 121.2a: Alms Collector, the one DrawCountR producer.
        Spec.it s "DrawCountR (Alms Collector)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.DrawCountR (DrawCountR.MkDrawCountR (ControllerRelation.Related PlayerRelation.Opponent) 2 DrawCountRewrite.EachDrawOne))
            " {\"type\":\"DrawCountR\",\"value\":{\"whose\":{\"type\":\"Opponent\"},\"atLeast\":2,\"rewrite\":{\"type\":\"EachDrawOne\"}}} "
        -- CR 701.17a: Bruvac the Grandiloquent.
        Spec.it s "InstructionR (Bruvac the Grandiloquent)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.InstructionR (InstructionR.MkInstructionR PlayerInstruction.MillCards (ControllerRelation.Related PlayerRelation.Opponent) (InstructionRewrite.Scaled (Scaling.Multiply 2))))
            " {\"type\":\"InstructionR\",\"value\":{\"instruction\":{\"type\":\"MillCards\"},\"whose\":{\"type\":\"Opponent\"},\"rewrite\":{\"type\":\"Scaled\",\"value\":{\"type\":\"Multiply\",\"value\":2}}}} "
        -- CR 706.6: Pixie Guide.
        Spec.it s "DieRollR (Pixie Guide)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.DieRollR (DieRollR.MkDieRollR (ControllerRelation.Related PlayerRelation.You) DieRollRewrite.ExtraIgnoringLowest))
            " {\"type\":\"DieRollR\",\"value\":{\"whose\":{\"type\":\"You\"},\"rewrite\":{\"type\":\"ExtraIgnoringLowest\"}}} "
        -- The Unstable FAQ: Steamflogger Boss.
        Spec.it s "AssembleR (Steamflogger Boss)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.AssembleR (Filter.HasSubtype Subtype.Rigger))
            " {\"type\":\"AssembleR\",\"value\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Rigger\"}}} "
        -- CR 701.31 / 614.1a: Susan Foreman.
        Spec.it s "PlaneswalkR (Susan Foreman)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.PlaneswalkR (PlaneswalkR.MkPlaneswalkR (ControllerRelation.Related PlayerRelation.You) Nothing PlaneswalkRewrite.ArrangeTopTwo))
            " {\"type\":\"PlaneswalkR\",\"value\":{\"whose\":{\"type\":\"You\"},\"rewrite\":{\"type\":\"ArrangeTopTwo\"}}} "
        -- CR 701.22a: Eligeth, Crossroads Augur.
        Spec.it s "InstructionR (Eligeth, Crossroads Augur)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.InstructionR (InstructionR.MkInstructionR PlayerInstruction.Scry (ControllerRelation.Related PlayerRelation.You) InstructionRewrite.DrawInstead))
            " {\"type\":\"InstructionR\",\"value\":{\"instruction\":{\"type\":\"Scry\"},\"whose\":{\"type\":\"You\"},\"rewrite\":{\"type\":\"DrawInstead\"}}} "
        -- A fixed kind, a real filter, and CR 614.16's AddMore.
        Spec.it s "CounterR (Hardened Scales)" $
          Common.assertCodec
            s
            codec
            ( ReplacementEffect.CounterR
                ( CounterR.MkCounterR
                    CounterPattern.MkCounterPattern
                      { CounterPattern.whichKind = Just CounterKind.PlusOnePlusOne,
                        CounterPattern.subject = CounterSubject.ByAnything,
                        CounterPattern.whose = ControllerRelation.Related PlayerRelation.You,
                        CounterPattern.onWhat = Filter.HasCardType CardType.Creature,
                        CounterPattern.onWho = Nothing
                      }
                    (Scaling.AddMore 1)
                )
            )
            " {\"type\":\"CounterR\",\"value\":{\"matching\":{\"whichKind\":{\"type\":\"PlusOnePlusOne\"},\"subject\":{\"type\":\"ByAnything\"},\"whose\":{\"type\":\"You\"},\"onWhat\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"scaling\":{\"type\":\"AddMore\",\"value\":1}}} "
        -- whichKind = Nothing means any kind, never "no kind", and the trivial filter
        -- matches every permanent. An absent whichKind key is what that Nothing
        -- means.
        Spec.it s "CounterR (Doubling Season, whichKind omitted)" $
          Common.assertCodec
            s
            codec
            ( ReplacementEffect.CounterR
                ( CounterR.MkCounterR
                    CounterPattern.MkCounterPattern
                      { CounterPattern.whichKind = Nothing,
                        CounterPattern.subject = CounterSubject.ByEffect,
                        CounterPattern.whose = ControllerRelation.Related PlayerRelation.You,
                        CounterPattern.onWhat = Filter.And [],
                        CounterPattern.onWho = Nothing
                      }
                    (Scaling.Multiply 2)
                )
            )
            " {\"type\":\"CounterR\",\"value\":{\"matching\":{\"subject\":{\"type\":\"ByEffect\"},\"whose\":{\"type\":\"You\"},\"onWhat\":{\"type\":\"And\",\"value\":[]}},\"scaling\":{\"type\":\"Multiply\",\"value\":2}}} "
        -- Pattern and scaling are both DATA, so both have to survive the trip.
        Spec.it s "TokenR (Doubling Season, tokens)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.TokenR (TokenR.MkTokenR TokenPattern.MkTokenPattern {TokenPattern.whose = ControllerRelation.Related PlayerRelation.You, TokenPattern.whatToken = Filter.And []} (Just (Scaling.Multiply 2)) Nothing))
            " {\"type\":\"TokenR\",\"value\":{\"matching\":{\"whose\":{\"type\":\"You\"}},\"scaling\":{\"type\":\"Multiply\",\"value\":2}}} "
        -- CR 614.1b: a skip carries a pattern and no rewrite, so the payload is the
        -- pattern itself rather than the usual two-element array. whosePhase =
        -- Nothing is the shape a card actually writes.
        Spec.it s "PhaseR (Eon Hub, symmetric skip)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.PhaseR PhasePattern.MkPhasePattern {PhasePattern.whichPhase = PhaseSelector.Step (Phase.Beginning BeginningStep.Upkeep), PhasePattern.whosePhase = Nothing})
            " {\"type\":\"PhaseR\",\"value\":{\"whichPhase\":{\"type\":\"Step\",\"value\":{\"type\":\"Beginning\",\"value\":{\"type\":\"Upkeep\"}}}}} "
        -- The baked player-scoped whosePhase = Just, which only Resolve's
        -- SkipPhase arm produces and no card authors (#437). The codec has to
        -- carry it either way.
        Spec.it s "PhaseR (Fatigue, player-scoped skip)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.PhaseR PhasePattern.MkPhasePattern {PhasePattern.whichPhase = PhaseSelector.Step (Phase.Beginning BeginningStep.DrawStep), PhasePattern.whosePhase = Just (PlayerId.MkPlayerId 1)})
            " {\"type\":\"PhaseR\",\"value\":{\"whichPhase\":{\"type\":\"Step\",\"value\":{\"type\":\"Beginning\",\"value\":{\"type\":\"DrawStep\"}}},\"whosePhase\":1}} "
        -- The whole-phase selector, once Resolve has baked the player its resolution
        -- named -- the shape a bare Phase cannot spell (CR 500.1).
        Spec.it s "PhaseR (Stonehorn Dignitary, whole-phase skip)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.PhaseR PhasePattern.MkPhasePattern {PhasePattern.whichPhase = PhaseSelector.CombatPhase, PhasePattern.whosePhase = Just (PlayerId.MkPlayerId 1)})
            " {\"type\":\"PhaseR\",\"value\":{\"whichPhase\":{\"type\":\"CombatPhase\"},\"whosePhase\":1}} "
        -- CR 614.1e / 702.37b: megamorph's "as this permanent is turned face up, put a
        -- +1/+1 counter on it". Minted by Parun.Engine.Keyword rather than written by a
        -- card, and it round-trips anyway -- every arm of this type does.
        Spec.it s "TurnUpR (megamorph, CR 702.37b)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.TurnUpR (TurnUpR.MkTurnUpR Filter.IsSource (Just TurnUpProcedure.Morph) Nothing (TurnUpRewrite.WithCounters (WithCounters.one CounterKind.PlusOnePlusOne (Quantity.Literal 1)))))
            " {\"type\":\"TurnUpR\",\"value\":{\"matching\":{\"type\":\"IsSource\"},\"requiring\":{\"type\":\"Morph\"},\"rewrite\":{\"type\":\"WithCounters\",\"value\":[{\"kind\":{\"type\":\"PlusOnePlusOne\"},\"count\":{\"type\":\"Literal\",\"value\":1}}]}}} "
        -- CR 701.3a: Dinosaur Headdress's "as this Equipment becomes attached".
        Spec.it s "AttachR (Dinosaur Headdress)" $
          Common.assertCodec
            s
            codec
            (ReplacementEffect.AttachR (AttachR.MkAttachR Filter.IsSource (AttachRewrite.AsCopy (AsCopy.MkAsCopy (Filter.HasCardType CardType.Creature) [] False Seq.empty (CopyDomain.InPile ExiledPile.CraftMaterials) Nothing CopyRecipient.ItsHost False))))
            " {\"type\":\"AttachR\",\"value\":{\"matching\":{\"type\":\"IsSource\"},\"rewrite\":{\"type\":\"AsCopy\",\"value\":{\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"among\":{\"type\":\"InPile\",\"value\":{\"type\":\"CraftMaterials\"}},\"recipient\":{\"type\":\"ItsHost\"},\"optional\":false}}}} "
        Spec.it s "has a schema" $ Common.assertHasSchema s codec
