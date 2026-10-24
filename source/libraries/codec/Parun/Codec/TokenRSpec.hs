module Parun.Codec.TokenRSpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.TokenR as TokenR
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.Counterability as Counterability
import qualified Parun.Types.Face as Face
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Layout as Layout
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Scaling as Scaling
import qualified Parun.Types.TokenPattern as TokenPattern
import qualified Parun.Types.TokenPlus as TokenPlus
import qualified Parun.Types.TokenR as TokenR
import qualified Parun.Types.TypeLine as TypeLine

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TokenR" $ do
  let codec = TokenR.codec Card.codec
  -- CR 614.16: Doubling Season doubles the tokens you create.
  Spec.it s "MkTokenR" $
    Common.assertCodec
      s
      codec
      ( TokenR.MkTokenR
          { TokenR.matching = TokenPattern.MkTokenPattern {TokenPattern.whose = ControllerRelation.Related PlayerRelation.You, TokenPattern.whatToken = Filter.And []},
            TokenR.scaling = Just (Scaling.Multiply 2),
            TokenR.plus = Nothing
          }
      )
      " {\"matching\":{\"whose\":{\"type\":\"You\"}},\"scaling\":{\"type\":\"Multiply\",\"value\":2}} "
  -- CR 614.1a: Queen Allenal of Ruadach appends a token and scales nothing.
  Spec.it s "an append with no scaling" $
    Common.assertCodec
      s
      codec
      ( TokenR.MkTokenR
          { TokenR.matching = TokenPattern.MkTokenPattern {TokenPattern.whose = ControllerRelation.Related PlayerRelation.You, TokenPattern.whatToken = Filter.HasCardType CardType.Creature},
            TokenR.scaling = Nothing,
            TokenR.plus = Just (TokenPlus.One soldier)
          }
      )
      " {\"matching\":{\"whose\":{\"type\":\"You\"},\"whatToken\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"plus\":{\"type\":\"One\",\"value\":{\"faces\":[{\"name\":\"Soldier Token\",\"typeLine\":{\"types\":[{\"type\":\"Creature\"}]}}]}}} "
  -- CR 614.1a: Chatterfang, Squirrel General appends one per token created.
  Spec.it s "an append sized by the event" $
    Common.assertCodec
      s
      codec
      ( TokenR.MkTokenR
          { TokenR.matching = TokenPattern.MkTokenPattern {TokenPattern.whose = ControllerRelation.Related PlayerRelation.You, TokenPattern.whatToken = Filter.And []},
            TokenR.scaling = Nothing,
            TokenR.plus = Just (TokenPlus.ThatMany soldier)
          }
      )
      " {\"matching\":{\"whose\":{\"type\":\"You\"}},\"plus\":{\"type\":\"ThatMany\",\"value\":{\"faces\":[{\"name\":\"Soldier Token\",\"typeLine\":{\"types\":[{\"type\":\"Creature\"}]}}]}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec

-- A one-face creature token with every other field at the value
-- Parun.Codec.Face's decoder defaults it to; Parun.Codec.CardSpec's bareFace.
soldier :: Card.Card
soldier =
  Card.MkCard
    { Card.layout = Layout.Normal,
      Card.faces =
        NonEmpty.singleton
          Face.MkFace
            { Face.name = CardName.MkCardName (Text.pack "Soldier Token"),
              Face.oracleText = Nothing,
              Face.manaCost = Nothing,
              Face.typeLine = TypeLine.MkTypeLine Set.empty (Set.singleton CardType.Creature) Set.empty,
              Face.power = Nothing,
              Face.toughness = Nothing,
              Face.loyalty = Nothing,
              Face.defense = Nothing,
              Face.startingIntensity = Nothing,
              Face.vanguard = Nothing,
              Face.canBeYourCommander = False,
              Face.claimsStartingPlayer = False,
              Face.anteOnly = False,
              Face.keywords = Map.empty,
              Face.colorIndicator = Set.empty,
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
