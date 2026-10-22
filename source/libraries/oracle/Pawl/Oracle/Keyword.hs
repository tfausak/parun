-- Keyword abilities (CR 702) as Oracle text prints them.
module Pawl.Oracle.Keyword where

import qualified Data.Char as Char
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Text as Text
import qualified Numeric.Natural as Natural
import qualified Pawl.Oracle.Cost as Cost
import qualified Pawl.Oracle.Filter as Filter
import qualified Pawl.Oracle.Prose as Prose
import qualified Pawl.Types.Backup as Backup
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Cycling as Cycling
import qualified Pawl.Types.Devour as Devour
import qualified Pawl.Types.DevourCount as DevourCount
import qualified Pawl.Types.Equip as Equip
import qualified Pawl.Types.EquipTarget as EquipTarget
import qualified Pawl.Types.Filter as Filter.Type
import qualified Pawl.Types.ForetellCost as ForetellCost
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.KeywordCount as KeywordCount
import qualified Pawl.Types.KeywordFamily as KeywordFamily
import qualified Pawl.Types.MadnessCost as MadnessCost
import qualified Pawl.Types.Morph as Morph
import qualified Pawl.Types.MorphVariant as MorphVariant
import qualified Pawl.Types.Protection as Protection
import qualified Pawl.Types.Reinforce as Reinforce
import qualified Pawl.Types.Splice as Splice
import qualified Pawl.Types.Subtype as Subtype
import qualified Pawl.Types.Suspend as Suspend
import qualified Pawl.Types.SuspendCounters as SuspendCounters
import qualified Pawl.Types.Ward as Ward

-- | A face's keywords, one line per instance (a keyword printed twice is two
-- instances, CR 702.1), except that protections share one. Lines come out in
-- no particular order, which Pawl.Oracle.Normalise absorbs: the face keeps no
-- printed order to follow.
lines :: Text.Text -> Map.Map Keyword.Keyword Natural.Natural -> [[Text.Text]]
lines self keywords = do
  let instances = concatMap (\(k, n) -> List.genericReplicate n k) (Map.toAscList keywords)
      (protections, others) = List.partition isProtection instances
  separate <- traverse (printed self) others
  shared <- protectionLines self protections
  [separate <> shared]

-- | Whether the keyword is a protection (CR 702.16).
isProtection :: Keyword.Keyword -> Bool
isProtection k = case k of
  Keyword.Protection _ -> True
  _ -> False

-- | Protections all on one line, as Oracle text prints more than one:
-- "Protection from black and from red" (Paladin en-Vec), "Protection from
-- white, from blue, and from black".
protectionLines :: Text.Text -> [Keyword.Keyword] -> [[Text.Text]]
protectionLines self protections = case protections of
  [] -> [[]]
  [one] -> traverse (printed self) [one]
  _ -> do
    let from k = case k of
          Keyword.Protection p | Maybe.isNothing (Protection.spares p) -> fmap (Text.pack "from " <>) (quality self (Protection.quality p))
          _ -> []
    qs <- traverse from protections
    [[Text.pack "Protection " <> Prose.listing "and" qs]]

-- | How Oracle text prints a keyword, given what the card calls itself; none
-- for one this does not spell yet. A landwalk over a subtype is "[type]walk"
-- (CR 702.14a). No wildcard arm: a new keyword fails to compile here until it
-- is given its printed form or answers none.
printed :: Text.Text -> Keyword.Keyword -> [Text.Text]
printed self keyword = case keyword of
  Keyword.Deathtouch -> [Text.pack "Deathtouch"]
  Keyword.Defender -> [Text.pack "Defender"]
  Keyword.DoubleStrike -> [Text.pack "Double strike"]
  Keyword.Equip e -> case (Equip.quality e, Equip.target e) of
    (Nothing, EquipTarget.Creature) -> Cost.keyworded self (Text.pack "Equip") (Equip.cost e)
    _ -> []
  Keyword.FirstStrike -> [Text.pack "First strike"]
  Keyword.Flash -> [Text.pack "Flash"]
  Keyword.Flying -> [Text.pack "Flying"]
  Keyword.Haste -> [Text.pack "Haste"]
  Keyword.Hexproof Nothing -> [Text.pack "Hexproof"]
  Keyword.Hexproof (Just f) -> fmap (Text.pack "Hexproof from " <>) (quality self f)
  Keyword.Indestructible -> [Text.pack "Indestructible"]
  Keyword.Intimidate -> [Text.pack "Intimidate"]
  Keyword.Landwalk f -> landwalk self f
  Keyword.Lifelink -> [Text.pack "Lifelink"]
  Keyword.LivingMetal -> [Text.pack "Living metal"]
  Keyword.MoreThanMeetsTheEye c -> Cost.keyworded self (Text.pack "More Than Meets the Eye") c
  Keyword.Protection p -> case Protection.spares p of
    Nothing -> fmap (Text.pack "Protection from " <>) (quality self (Protection.quality p))
    Just _ -> []
  Keyword.Reach -> [Text.pack "Reach"]
  Keyword.Shroud -> [Text.pack "Shroud"]
  Keyword.Trample -> [Text.pack "Trample"]
  Keyword.TrampleOverPlaneswalkers -> [Text.pack "Trample over planeswalkers"]
  Keyword.Vigilance -> [Text.pack "Vigilance"]
  Keyword.Ward w -> case Ward.perEach w of
    Nothing -> Cost.keyworded self (Text.pack "Ward") (Ward.cost w)
    Just _ -> []
  Keyword.Banding -> [Text.pack "Banding"]
  Keyword.Rampage n -> [numbered "Rampage" n]
  Keyword.CumulativeUpkeep c -> Cost.keyworded self (Text.pack "Cumulative upkeep") c
  Keyword.Flanking -> [Text.pack "Flanking"]
  Keyword.Phasing -> [Text.pack "Phasing"]
  Keyword.Buyback c -> Cost.keyworded self (Text.pack "Buyback") c
  Keyword.Shadow -> [Text.pack "Shadow"]
  Keyword.Cycling c -> case Cycling.searchFor c of
    Nothing -> Cost.keyworded self (Text.pack "Cycling") (Cycling.cost c)
    Just _ -> []
  Keyword.Echo c -> Cost.keyworded self (Text.pack "Echo") c
  Keyword.Horsemanship -> [Text.pack "Horsemanship"]
  Keyword.Fading n -> [numbered "Fading" n]
  Keyword.Kicker c -> Cost.keyworded self (Text.pack "Kicker") c
  Keyword.Multikicker c -> Cost.keyworded self (Text.pack "Multikicker") c
  Keyword.StickerKicker {} -> []
  Keyword.Flashback c -> Cost.keyworded self (Text.pack "Flashback") c
  Keyword.Fear -> [Text.pack "Fear"]
  Keyword.Morph m -> case Morph.variant m of
    MorphVariant.Plain -> Cost.keyworded self (Text.pack "Morph") (Morph.cost m)
    MorphVariant.Mega -> Cost.keyworded self (Text.pack "Megamorph") (Morph.cost m)
  Keyword.Amplify n -> [numbered "Amplify" n]
  Keyword.Provoke -> [Text.pack "Provoke"]
  Keyword.Storm -> [Text.pack "Storm"]
  Keyword.Affinity f -> fmap (Text.pack "Affinity for " <>) (quality self f)
  Keyword.Entwine c -> Cost.keyworded self (Text.pack "Entwine") c
  Keyword.Modular n -> case n of
    Just m -> [numbered "Modular" m]
    Nothing -> []
  Keyword.Sunburst -> [Text.pack "Sunburst"]
  Keyword.Bushido n -> [numbered "Bushido" n]
  Keyword.Soulshift n -> [numbered "Soulshift" n]
  Keyword.Splice sp -> do
    onto <- Filter.phrase (Splice.onto sp) (keywordWord self) >>= Filter.describe Filter.Singular (Filter.MkNoun Text.empty Nothing)
    Cost.keyworded self (Text.pack "Splice onto " <> onto) (Splice.cost sp)
  Keyword.Offering {} -> []
  Keyword.Ninjutsu {} -> []
  Keyword.Epic -> [Text.pack "Epic"]
  Keyword.Paradigm -> [Text.pack "Paradigm"]
  Keyword.Convoke -> [Text.pack "Convoke"]
  Keyword.Dredge n -> [numbered "Dredge" n]
  Keyword.Bloodthirst n -> case n of
    Just m -> [numbered "Bloodthirst" m]
    Nothing -> []
  Keyword.Haunt -> [Text.pack "Haunt"]
  Keyword.Replicate c -> Cost.keyworded self (Text.pack "Replicate") c
  Keyword.Graft n -> [numbered "Graft" n]
  Keyword.Recover c -> Cost.keyworded self (Text.pack "Recover") c
  Keyword.Ripple n -> [numbered "Ripple" n]
  Keyword.SplitSecond -> [Text.pack "Split second"]
  Keyword.Suspend (Just sp) -> case Suspend.counters sp of
    SuspendCounters.Literal n -> do
      text <- Cost.cost self (Suspend.cost sp)
      [numbered "Suspend" n <> Text.pack "\8212" <> text]
    SuspendCounters.Variable _ -> []
  Keyword.Suspend Nothing -> []
  Keyword.Vanishing Nothing -> [Text.pack "Vanishing"]
  Keyword.Vanishing (Just n) -> [numbered "Vanishing" n]
  Keyword.Absorb n -> [numbered "Absorb" n]
  Keyword.AuraSwap c -> Cost.keyworded self (Text.pack "Aura swap") c
  Keyword.Delve -> [Text.pack "Delve"]
  Keyword.Fortify c -> Cost.keyworded self (Text.pack "Fortify") c
  Keyword.Frenzy n -> [numbered "Frenzy" n]
  Keyword.Gravestorm -> [Text.pack "Gravestorm"]
  Keyword.Poisonous n -> [numbered "Poisonous" n]
  Keyword.Champion {} -> []
  Keyword.Changeling -> [Text.pack "Changeling"]
  Keyword.Evoke c -> Cost.keyworded self (Text.pack "Evoke") c
  Keyword.Hideaway n -> [numbered "Hideaway" n]
  Keyword.Prowl c -> Cost.keyworded self (Text.pack "Prowl") c
  Keyword.Reinforce r -> do
    text <- Cost.cost self (Reinforce.cost r)
    [numbered "Reinforce" (Reinforce.amount r) <> Text.pack "\8212" <> text]
  Keyword.Conspire -> [Text.pack "Conspire"]
  Keyword.Persist -> [Text.pack "Persist"]
  Keyword.Wither -> [Text.pack "Wither"]
  Keyword.Devour d -> case (Devour.quality d, Devour.count d) of
    (Nothing, DevourCount.Fixed n) -> [numbered "Devour" n]
    (Just f, DevourCount.Fixed n) -> do
      word <- Filter.phrase f (keywordWord self) >>= Filter.describe Filter.Singular (Filter.MkNoun Text.empty Nothing)
      [Text.pack "Devour " <> word <> Text.pack (" " <> show n)]
    (_, DevourCount.Devoured) -> []
  Keyword.Exalted -> [Text.pack "Exalted"]
  Keyword.Unearth c -> Cost.keyworded self (Text.pack "Unearth") c
  Keyword.Cascade -> [Text.pack "Cascade"]
  Keyword.Annihilator n -> [numbered "Annihilator" n]
  Keyword.LevelUp c -> Cost.keyworded self (Text.pack "Level up") c
  Keyword.Infect -> [Text.pack "Infect"]
  Keyword.BattleCry -> [Text.pack "Battle cry"]
  Keyword.LivingWeapon -> [Text.pack "Living weapon"]
  Keyword.Undying -> [Text.pack "Undying"]
  Keyword.Miracle c -> Cost.keyworded self (Text.pack "Miracle") c
  Keyword.Soulbond -> [Text.pack "Soulbond"]
  Keyword.Overload c -> Cost.keyworded self (Text.pack "Overload") c
  Keyword.Unleash -> [Text.pack "Unleash"]
  Keyword.Cipher -> [Text.pack "Cipher"]
  Keyword.Evolve -> [Text.pack "Evolve"]
  Keyword.Extort -> [Text.pack "Extort"]
  Keyword.Fuse -> [Text.pack "Fuse"]
  Keyword.Tribute n -> [numbered "Tribute" n]
  Keyword.Dethrone -> [Text.pack "Dethrone"]
  Keyword.HiddenAgenda -> [Text.pack "Hidden agenda"]
  Keyword.Outlast c -> Cost.keyworded self (Text.pack "Outlast") c
  Keyword.Prowess -> [Text.pack "Prowess"]
  Keyword.Dash c -> Cost.keyworded self (Text.pack "Dash") c
  Keyword.Exploit -> [Text.pack "Exploit"]
  Keyword.Menace -> [Text.pack "Menace"]
  Keyword.Renown n -> [numbered "Renown" n]
  Keyword.Awaken {} -> []
  Keyword.Devoid -> [Text.pack "Devoid"]
  Keyword.Ingest -> [Text.pack "Ingest"]
  Keyword.Myriad -> [Text.pack "Myriad"]
  Keyword.Surge c -> Cost.keyworded self (Text.pack "Surge") c
  Keyword.Skulk -> [Text.pack "Skulk"]
  Keyword.SpaceSculptor -> [Text.pack "Space sculptor"]
  Keyword.Emerge {} -> []
  Keyword.Escalate c -> Cost.keyworded self (Text.pack "Escalate") c
  Keyword.Melee -> [Text.pack "Melee"]
  Keyword.Crew n -> [numbered "Crew" n]
  Keyword.Fabricate n -> [numbered "Fabricate" n]
  Keyword.Partner -> [Text.pack "Partner"]
  Keyword.PartnerText {} -> []
  Keyword.PartnerWith name -> [Text.pack "Partner with " <> CardName.unwrap name]
  Keyword.ChooseABackground -> [Text.pack "Choose a Background"]
  Keyword.DoctorsCompanion -> [Text.pack "Doctor's companion"]
  Keyword.Undaunted -> [Text.pack "Undaunted"]
  Keyword.Improvise -> [Text.pack "Improvise"]
  Keyword.Aftermath -> [Text.pack "Aftermath"]
  Keyword.Embalm c -> Cost.keyworded self (Text.pack "Embalm") c
  Keyword.Eternalize c -> Cost.keyworded self (Text.pack "Eternalize") c
  Keyword.Afflict n -> [numbered "Afflict" n]
  Keyword.Ascend -> [Text.pack "Ascend"]
  Keyword.Assist -> [Text.pack "Assist"]
  Keyword.JumpStart -> [Text.pack "Jump-start"]
  Keyword.Mentor -> [Text.pack "Mentor"]
  Keyword.Afterlife n -> [numbered "Afterlife" n]
  Keyword.Riot -> [Text.pack "Riot"]
  Keyword.Spectacle c -> Cost.keyworded self (Text.pack "Spectacle") c
  Keyword.Escape c -> Cost.keyworded self (Text.pack "Escape") c
  Keyword.Companion {} -> []
  Keyword.Foretell f -> case f of
    ForetellCost.Stated c -> Cost.keyworded self (Text.pack "Foretell") c
    ForetellCost.ManaCostReducedBy _ -> []
  Keyword.Demonstrate -> [Text.pack "Demonstrate"]
  Keyword.Daybound -> [Text.pack "Daybound"]
  Keyword.Nightbound -> [Text.pack "Nightbound"]
  Keyword.Decayed -> [Text.pack "Decayed"]
  Keyword.Cleave c -> Cost.keyworded self (Text.pack "Cleave") c
  Keyword.Training -> [Text.pack "Training"]
  Keyword.Compleated -> [Text.pack "Compleated"]
  Keyword.Reconfigure c -> Cost.keyworded self (Text.pack "Reconfigure") c
  Keyword.Blitz c -> Cost.keyworded self (Text.pack "Blitz") c
  Keyword.Casualty n -> [numbered "Casualty" n]
  Keyword.ReadAhead -> [Text.pack "Read ahead"]
  Keyword.Ravenous -> [Text.pack "Ravenous"]
  Keyword.Squad c -> Cost.keyworded self (Text.pack "Squad") c
  Keyword.Prototype {} -> []
  Keyword.ForMirrodin -> [Text.pack "For Mirrodin!"]
  Keyword.Toxic n -> [numbered "Toxic" n]
  Keyword.Backup b -> [numbered "Backup" (Backup.count b)]
  Keyword.Bargain -> [Text.pack "Bargain"]
  Keyword.Craft {} -> []
  Keyword.Disguise c -> Cost.keyworded self (Text.pack "Disguise") c
  Keyword.Plot c -> Cost.keyworded self (Text.pack "Plot") c
  Keyword.Saddle n -> [numbered "Saddle" n]
  Keyword.Spree -> [Text.pack "Spree"]
  Keyword.Offspring c -> Cost.keyworded self (Text.pack "Offspring") c
  Keyword.Gift {} -> []
  Keyword.Freerunning c -> Cost.keyworded self (Text.pack "Freerunning") c
  Keyword.Impending {} -> []
  Keyword.Exhaust -> [Text.pack "Exhaust"]
  Keyword.Boast -> [Text.pack "Boast"]
  Keyword.PowerUp -> [Text.pack "Power-up"]
  Keyword.ClassLevel {} -> []
  Keyword.Forecast -> [Text.pack "Forecast"]
  Keyword.StartYourEngines -> [Text.pack "Start your engines!"]
  Keyword.JobSelect -> [Text.pack "Job select"]
  Keyword.Tiered -> [Text.pack "Tiered"]
  Keyword.Exert -> [Text.pack "Exert"]
  Keyword.Enlist -> [Text.pack "Enlist"]
  Keyword.Bestow c -> Cost.keyworded self (Text.pack "Bestow") c
  Keyword.Station -> [Text.pack "Station"]
  Keyword.Mutate c -> Cost.keyworded self (Text.pack "Mutate") c
  Keyword.UmbraArmor -> [Text.pack "Umbra armor"]
  Keyword.Retrace -> [Text.pack "Retrace"]
  Keyword.Mayhem Nothing -> [Text.pack "Mayhem"]
  Keyword.Mayhem (Just c) -> Cost.keyworded self (Text.pack "Mayhem") c
  Keyword.Madness m -> case m of
    MadnessCost.Stated c -> Cost.keyworded self (Text.pack "Madness") c
    MadnessCost.OwnManaCost -> []
  Keyword.Rebound -> [Text.pack "Rebound"]
  Keyword.Scavenge c -> Cost.keyworded self (Text.pack "Scavenge") c
  Keyword.Encore c -> Cost.keyworded self (Text.pack "Encore") c
  Keyword.Teamwork {} -> []
  Keyword.WebSlinging c -> Cost.keyworded self (Text.pack "Web-slinging") c
  Keyword.Sneak c -> Cost.keyworded self (Text.pack "Sneak") c
  Keyword.Increment -> [Text.pack "Increment"]
  Keyword.Storied -> [Text.pack "Storied"]
  Keyword.Mobilize c -> counted "Mobilize" c
  Keyword.Firebending c -> counted "Firebending" c
  Keyword.Transmute c -> Cost.keyworded self (Text.pack "Transmute") c
  Keyword.Transfigure c -> Cost.keyworded self (Text.pack "Transfigure") c
  Keyword.Warp c -> Cost.keyworded self (Text.pack "Warp") c
  Keyword.Disturb c -> Cost.keyworded self (Text.pack "Disturb") c
  Keyword.Harmonize c -> Cost.keyworded self (Text.pack "Harmonize") c

-- | A keyword family as Oracle text names every keyword of it, in lower case
-- ("loses hexproof"), landwalk's as its abilities (Hammerheim, CR 702.14a),
-- for a family whose name is one word; a longer one is not spelled out here
-- yet.
family :: KeywordFamily.KeywordFamily -> [Text.Text]
family f = case f of
  KeywordFamily.Landwalk -> [Text.pack "all landwalk abilities"]
  _ ->
    let name = Text.pack (show f)
     in [Text.toLower name | Text.length (Text.filter Char.isUpper name) == 1]

-- | A keyword counting a printed number: "Mobilize 3".
counted :: String -> KeywordCount.KeywordCount keyword -> [Text.Text]
counted name c = case c of
  KeywordCount.Fixed n -> [numbered name n]
  _ -> []

-- | A keyword and its number: "Rampage 2".
numbered :: String -> Natural.Natural -> Text.Text
numbered name n = Text.pack (name <> " " <> show n)

-- | What a keyword is "from" or "for": a colour as its name ("protection from
-- red"), anything else as the plural it describes ("affinity for artifacts").
quality :: Text.Text -> Filter.Type.Filter Keyword.Keyword -> [Text.Text]
quality self f = case f of
  Filter.Type.HasColor c -> [Filter.color c]
  _ -> Filter.phrase f (keywordWord self) >>= Filter.describe Filter.Plural (Filter.MkNoun Text.empty Nothing)

-- | A keyword as a filter names it: "with flying".
keywordWord :: Text.Text -> Keyword.Keyword -> [Text.Text]
keywordWord self k = fmap Text.toLower (printed self k)

-- | A landwalk's quality as the word before "walk": "swamp" for a Swamp,
-- "snow swamp" for a snow Swamp, "nonbasic land" for a nonbasic land, and
-- "artifact land" for an artifact land (CR 702.14a, CR 702.14c).
landwalk :: Text.Text -> Filter.Type.Filter Keyword.Keyword -> [Text.Text]
landwalk self f = do
  p <- Filter.phrase f (keywordWord self)
  before <- Filter.adjectiveText Filter.Singular (Filter.adjectives p)
  word <- case (Filter.nouns p, Filter.qualifiers p, f) of
    ([], [], _) -> [Text.pack "landwalk"]
    ([n], [], Filter.Type.HasCardType _) -> [Text.toLower (Filter.singular n) <> Text.pack " landwalk"]
    ([n], [], _) -> [Text.toLower (Filter.singular n) <> Text.pack "walk"]
    _ -> []
  [Prose.capitalise (Text.unwords (before <> [word]))]

-- | Every keyword 'printed' answers for with no payload: the words an ingested card's text may
standalone :: [Keyword.Keyword]
standalone =
  [ Keyword.Deathtouch,
    Keyword.Defender,
    Keyword.DoubleStrike,
    Keyword.FirstStrike,
    Keyword.Flash,
    Keyword.Flying,
    Keyword.Haste,
    Keyword.Hexproof Nothing,
    Keyword.Indestructible,
    Keyword.Intimidate,
    Keyword.Lifelink,
    Keyword.LivingMetal,
    Keyword.Reach,
    Keyword.Shroud,
    Keyword.Trample,
    Keyword.TrampleOverPlaneswalkers,
    Keyword.Vigilance,
    Keyword.Banding,
    Keyword.Flanking,
    Keyword.Phasing,
    Keyword.Shadow,
    Keyword.Horsemanship,
    Keyword.Fear,
    Keyword.Provoke,
    Keyword.Storm,
    Keyword.Sunburst,
    Keyword.Epic,
    Keyword.Paradigm,
    Keyword.Convoke,
    Keyword.Haunt,
    Keyword.SplitSecond,
    Keyword.Vanishing Nothing,
    Keyword.Delve,
    Keyword.Gravestorm,
    Keyword.Changeling,
    Keyword.Conspire,
    Keyword.Persist,
    Keyword.Wither,
    Keyword.Exalted,
    Keyword.Cascade,
    Keyword.Infect,
    Keyword.BattleCry,
    Keyword.LivingWeapon,
    Keyword.Undying,
    Keyword.Soulbond,
    Keyword.Unleash,
    Keyword.Cipher,
    Keyword.Evolve,
    Keyword.Extort,
    Keyword.Fuse,
    Keyword.Dethrone,
    Keyword.HiddenAgenda,
    Keyword.Prowess,
    Keyword.Exploit,
    Keyword.Menace,
    Keyword.Devoid,
    Keyword.Ingest,
    Keyword.Myriad,
    Keyword.Skulk,
    Keyword.Melee,
    Keyword.Partner,
    Keyword.ChooseABackground,
    Keyword.DoctorsCompanion,
    Keyword.Undaunted,
    Keyword.Improvise,
    Keyword.Aftermath,
    Keyword.Ascend,
    Keyword.Assist,
    Keyword.JumpStart,
    Keyword.Mentor,
    Keyword.Riot,
    Keyword.Demonstrate,
    Keyword.Daybound,
    Keyword.Nightbound,
    Keyword.Decayed,
    Keyword.Training,
    Keyword.Compleated,
    Keyword.ReadAhead,
    Keyword.Ravenous,
    Keyword.ForMirrodin,
    Keyword.Bargain,
    Keyword.SpaceSculptor,
    Keyword.Spree,
    Keyword.Exhaust,
    Keyword.Boast,
    Keyword.PowerUp,
    Keyword.Forecast,
    Keyword.StartYourEngines,
    Keyword.JobSelect,
    Keyword.Tiered,
    Keyword.Exert,
    Keyword.Enlist,
    Keyword.Station,
    Keyword.UmbraArmor,
    Keyword.Retrace,
    Keyword.Rebound,
    Keyword.Increment,
    Keyword.Storied,
    Keyword.Mayhem Nothing
  ]

-- | The landwalks 'printed' answers for that an ingested card's text may
-- name: one per basic land type (CR 702.14a, CR 305.6). Apart from
-- 'standalone', which holds the keywords the codec writes as a bare tag.
landwalks :: [Keyword.Keyword]
landwalks = [Keyword.Landwalk (Filter.Type.HasSubtype subtype) | subtype <- [Subtype.Plains, Subtype.Island, Subtype.Swamp, Subtype.Mountain, Subtype.Forest]]
