-- Continuous effects (CR 611) as Oracle text words them: what a modification
-- does to the objects it affects ("gets +3/+3", "gains flying"), for how long,
-- and the static abilities that generate them (CR 604).
module Pawl.Oracle.Continuous where

import qualified Control.Monad as Monad
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Pawl.Oracle.Filter as Filter
import qualified Pawl.Oracle.Keyword as Keyword.Oracle
import qualified Pawl.Oracle.Prose as Prose
import qualified Pawl.Oracle.Target as Target
import qualified Pawl.Types.Affected as Affected
import qualified Pawl.Types.Duration as Duration
import qualified Pawl.Types.Filter as Filter.Type
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.KeywordFamily as KeywordFamily
import qualified Pawl.Types.Modification as Modification
import qualified Pawl.Types.ModifyPowerToughness as ModifyPowerToughness
import qualified Pawl.Types.ObjectRef as ObjectRef
import qualified Pawl.Types.Pool as Pool
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.StaticAbility as StaticAbility
import qualified Pawl.Types.Subtype as Subtype
import qualified Pawl.Types.TargetSlot as TargetSlot

-- | Who the effect comes from, which picks the verb a keyword takes: an
-- effect a spell or ability creates "gains" it (CR 611.2), a static ability's
-- object "has" it (CR 604.1).
data Origin
  = Created
  | Static
  deriving (Eq, Show)

-- | Modifications to the same objects as one verb phrase agreeing with them:
-- "gets +2/+2 and gains flying", a run of keywords gained or lost joined
-- ("gain flying and first strike"). Several targets "each get" a change to
-- power and toughness (Hearts on Fire), so the change is to each of them.
-- Only power and toughness and keywords are spelled out here.
modifications :: Origin -> Filter.Number -> Bool -> (Keyword.Keyword -> [Text.Text]) -> [Modification.Modification ability] -> [Text.Text]
modifications origin number each named ms = do
  parts <- traverse part (List.groupBy (\a b -> Maybe.isJust (keywordOf a) && fmap fst (keywordOf a) == fmap fst (keywordOf b)) ms)
  [Prose.listing "and" parts]
  where
    verb one many = Text.pack $ case number of
      Filter.Singular -> one
      Filter.Plural -> many
    part group = case group of
      [Modification.ModifyPowerToughness pt] -> do
        let power = ModifyPowerToughness.power pt
            toughness = ModifyPowerToughness.toughness pt
        p <- signed toughness power
        t <- signed power toughness
        [verb "gets " (if each then "each get " else "get ") <> p <> Text.pack "/" <> t]
      m : _ | Just (gained, _) <- keywordOf m -> do
        keywords <- traverse (foldMap (either named Keyword.Oracle.family . snd) . keywordOf) group
        let change = case (gained, origin) of
              (False, _) -> verb "loses " "lose "
              (True, Created) -> verb "gains " "gain "
              (True, Static) -> verb "has " "have "
        [change <> Prose.listing "and" keywords]
      _ -> []

-- | The keyword the modification grants, or with False the one it takes away,
-- or every keyword of a family it takes away (CR 613.1f).
keywordOf :: Modification.Modification ability -> Maybe (Bool, Either Keyword.Keyword KeywordFamily.KeywordFamily)
keywordOf m = case m of
  Modification.GainKeyword k -> Just (True, Left k)
  Modification.LoseKeyword k -> Just (False, Left k)
  Modification.LoseKeywordFamily f -> Just (False, Right f)
  _ -> Nothing

-- | A change to power or toughness with its sign: "+3", "-2", "+X", and a
-- zero signed as the other change is, "+2/+0" and "-2/-0" (Saltfield
-- Recluse). The first argument is the other change.
signed :: Quantity.Quantity -> Quantity.Quantity -> [Text.Text]
signed other q = case q of
  Quantity.Literal n
    | n > 0 -> [Text.pack ("+" <> show n)]
    | n < 0 -> [Text.pack (show n)]
    | Quantity.Literal m <- other, m < 0 -> [Text.pack "-0"]
    | otherwise -> [Text.pack "+0"]
  Quantity.InSlot s | s == Target.xSlot -> [Text.pack "+X"]
  _ -> []

-- | How long a created effect lasts, or nothing for one that lasts until the
-- end of the game, which states no duration (CR 611.2a, Riding the Dilu
-- Horse). Only "until end of turn" is spelled out here.
duration :: Duration.Duration -> [Maybe Text.Text]
duration d = case d of
  Duration.UntilEndOfTurn -> [Just (Text.pack "until end of turn")]
  Duration.Indefinite -> [Nothing]
  _ -> []

-- | A static ability whose effect is one of the above on the objects it
-- affects (CR 604.1): "Creatures you control get +1/+1.", "Enchanted creature
-- gets +2/+2 and has trample." A condition, a zone it functions from, a
-- lingering duration or a name is not spelled out here.
static :: Target.Context -> Maybe Text.Text -> [TargetSlot.TargetSlot] -> StaticAbility.StaticAbility ability -> [Text.Text]
static context attached enchants a
  | Maybe.isNothing (StaticAbility.condition a),
    Set.null (StaticAbility.functionsFrom a),
    Maybe.isNothing (StaticAbility.lingers a),
    Maybe.isNothing (StaticAbility.name a) = do
      subject <- affected context attached enchants (StaticAbility.affected a)
      verb <- modifications Static (Target.number subject) False (Target.keyword context) (Foldable.toList (StaticAbility.modifications a))
      [Prose.sentence (Target.wording subject <> Text.pack " " <> verb)]
  | otherwise = []

-- | The objects a static ability affects, as its sentence's subject. The
-- object its source is attached to is named by the given word: "enchanted"
-- (CR 303.4b, CR 303.4m) or "equipped" (CR 301.5a).
affected :: Target.Context -> Maybe Text.Text -> [TargetSlot.TargetSlot] -> Affected.Affected -> [Target.Reference]
affected context attached enchants a = case a of
  Affected.Attached
    | Just word <- attached,
      [slot] <- enchants -> do
        (one, _) <- Target.described context slot
        [Target.MkReference (word <> Text.pack " " <> one) [] Filter.Singular]
  Affected.Matching f
    | elem attachedToSource (conjuncts f) -> do
        word <- Maybe.maybeToList attached
        p <- Filter.phrase (Filter.Type.And (filter (/= attachedToSource) (conjuncts f))) (Target.keyword context)
        one <- Filter.describe Filter.Singular Target.permanent p
        [Target.MkReference (word <> Text.pack " " <> one) [] Filter.Singular]
    | otherwise -> Target.object context Target.Affected (ObjectRef.EachMatching f)
  _ -> []
  where
    attachedToSource = Filter.Type.HasAttached Filter.Type.IsSource
    conjuncts g = case g of
      Filter.Type.And gs -> gs
      _ -> [g]

-- | What the object a permanent is attached to is called: "enchanted" for an
-- Aura's, or a creature's with bestow, which is attached as an Aura (CR
-- 702.103b), and "equipped" for an Equipment's.
attachedWord :: Set.Set Subtype.Subtype -> Bool -> Maybe Text.Text
attachedWord subtypes bestowed
  | Set.member Subtype.Aura subtypes || bestowed = Just (Text.pack "enchanted")
  | Set.member Subtype.Equipment subtypes = Just (Text.pack "equipped")
  | otherwise = Nothing

-- | An Aura's enchant ability (CR 702.5a): "Enchant creature". One enchanting
-- a card in a graveyard is not spelled out here.
enchant :: Target.Context -> TargetSlot.TargetSlot -> [Text.Text]
enchant context slot = do
  Monad.guard (case TargetSlot.pool slot of Pool.CardsInGraveyard _ -> False; _ -> True)
  (one, _) <- Target.described context slot
  [Text.pack "Enchant " <> one]
