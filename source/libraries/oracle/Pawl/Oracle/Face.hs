-- Faces as Oracle text describes them where a card holds one, a token's
-- (CR 111.4), and the face that holds nothing a renderer has not read.
module Pawl.Oracle.Face where

import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Numeric.Natural as Natural
import qualified Pawl.Oracle.Filter as Filter
import qualified Pawl.Oracle.Prose as Prose
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.Counterability as Counterability
import qualified Pawl.Types.Face as Face
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.Layout as Layout
import qualified Pawl.Types.ManaCost as ManaCost
import qualified Pawl.Types.Power as Power
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.Toughness as Toughness
import qualified Pawl.Types.TypeLine as TypeLine

-- | A token's characteristics as the instruction creating it describes them,
-- in both numbers: ("1/1 white Spirit creature token with flying", "1/1 white
-- Spirit creature tokens with flying"). Its subtypes stand in the order its
-- name gives them, since a token's name is its subtypes plus "Token" (CR
-- 111.4). A token with abilities other than keywords, a supertype, a name of
-- its own, or a power or toughness that is not a number is not spelled out
-- here.
token :: (Keyword.Keyword -> [Text.Text]) -> Card.Card -> [(Text.Text, Text.Text)]
token named card = case Card.faces card of
  face NonEmpty.:| []
    | Card.layout card == Layout.Normal,
      Just (Quantity.Literal p) <- fmap Power.unwrap (Face.power face),
      Just (Quantity.Literal t) <- fmap Toughness.unwrap (Face.toughness face),
      p >= 0,
      t >= 0,
      all (== 1) (Face.keywords face),
      Set.null (TypeLine.supertypes (Face.typeLine face)),
      face == bare (Face.name face) Nothing Nothing (Face.colorIndicator face) (Face.typeLine face) (Face.power face) (Face.toughness face) (Face.keywords face) -> do
        let line = Face.typeLine face
        names <- traverse Filter.subtype (Set.toList (TypeLine.subtypes line))
        subtypes <- case Text.stripSuffix (Text.pack " Token") (CardName.unwrap (Face.name face)) of
          Just prefix | List.sort (Text.words prefix) == List.sort names -> [Text.words prefix]
          _ -> []
        keywords <- traverse named (Map.keys (Face.keywords face))
        colors <- case Set.toList (Face.colorIndicator face) of
          [] -> [[Text.pack "colorless"]]
          cs -> fmap (\ordered -> [Prose.listing "and" (fmap Filter.color ordered)]) (Maybe.maybeToList (colorOrder cs))
        let types = fmap (Filter.cardType Filter.Singular) (Set.toList (TypeLine.types line))
            front = Text.unwords ([Text.pack (show p <> "/" <> show t)] <> colors <> subtypes <> types)
            with = if null keywords then Text.empty else Text.pack " with " <> Prose.listing "and" keywords
        [(front <> Text.pack " token" <> with, front <> Text.pack " tokens" <> with)]
  _ -> []

-- | Colours in the order a mana cost writes them: the one turn of the colour
-- wheel (white, blue, black, red, green) spanning the fewest steps, "green
-- and white" but "white and black". A set no one turn spans most tightly is
-- not ordered here.
colorOrder :: [Color.Color] -> Maybe [Color.Color]
colorOrder cs =
  let wheel = List.sort cs
      turns = [drop i wheel <> take i wheel | i <- [0 .. length wheel - 1]]
      span' turn = case (turn, reverse turn) of
        (first : _, final : _) -> (fromEnum final - fromEnum first) `mod` 5
        _ -> 0
   in case filter ((== minimum (fmap span' turns)) . span') turns of
        [turn] -> Just turn
        [] -> Just []
        _ -> Nothing

-- | A face with the given Oracle text, characteristics and keywords and nothing
-- else. Every field is spelled out, so a field added to 'Face.Face' fails to
-- compile here rather than being silently ignored by 'Pawl.Oracle.faceAbilities'.
bare ::
  CardName.CardName ->
  Maybe Text.Text ->
  Maybe ManaCost.ManaCost ->
  Set.Set Color.Color ->
  TypeLine.TypeLine ->
  Maybe Power.Power ->
  Maybe Toughness.Toughness ->
  Map.Map Keyword.Keyword Natural.Natural ->
  Face.Face Card.Card
bare n t c i l p x k =
  Face.MkFace
    { Face.name = n,
      Face.oracleText = t,
      Face.manaCost = c,
      Face.typeLine = l,
      Face.power = p,
      Face.toughness = x,
      Face.loyalty = Nothing,
      Face.defense = Nothing,
      Face.startingIntensity = Nothing,
      Face.vanguard = Nothing,
      Face.canBeYourCommander = False,
      Face.claimsStartingPlayer = False,
      Face.anteOnly = False,
      Face.keywords = k,
      Face.colorIndicator = i,
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
      Face.crewRestrictions = [],
      Face.attackPermissions = [],
      Face.attachRestrictions = [],
      Face.entryRestrictions = [],
      Face.counterRestrictions = [],
      Face.activationProhibitions = [],
      Face.attackCosts = [],
      Face.blockCosts = [],
      Face.mulliganActions = [],
      Face.openingHandActions = [],
      Face.specialActions = []
    }
