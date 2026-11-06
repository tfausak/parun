module Parun.Codec.KeywordFamilySpec where

import qualified Parun.Codec.KeywordFamily as KeywordFamily
import qualified Parun.Json.Value as Value
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.KeywordFamily as KeywordFamily

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.KeywordFamily" $ do
  Spec.it s "Hexproof" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Hexproof
      " \"Hexproof\" "

  Spec.it s "Landwalk" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Landwalk
      " \"Landwalk\" "

  Spec.it s "Protection" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Protection
      " \"Protection\" "

  Spec.it s "Buyback" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Buyback
      " \"Buyback\" "

  Spec.it s "Cycling" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Cycling
      " \"Cycling\" "

  Spec.it s "Flashback" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Flashback
      " \"Flashback\" "

  Spec.it s "BeamMeUp" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.BeamMeUp
      " \"BeamMeUp\" "

  Spec.it s "Plot" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Plot
      " \"Plot\" "

  Spec.it s "Foretell" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Foretell
      " \"Foretell\" "

  Spec.it s "Miracle" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Miracle
      " \"Miracle\" "

  Spec.it s "Morph" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Morph
      " \"Morph\" "

  Spec.it s "Amplify" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Amplify
      " \"Amplify\" "

  Spec.it s "Kicker" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Kicker
      " \"Kicker\" "

  Spec.it s "Entwine" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Entwine
      " \"Entwine\" "

  Spec.it s "Bushido" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Bushido
      " \"Bushido\" "

  Spec.it s "Modular" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Modular
      " \"Modular\" "

  Spec.it s "Vanishing" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Vanishing
      " \"Vanishing\" "

  Spec.it s "Fading" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Fading
      " \"Fading\" "

  Spec.it s "Poisonous" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Poisonous
      " \"Poisonous\" "

  Spec.it s "Renown" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Renown
      " \"Renown\" "

  Spec.it s "Afterlife" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Afterlife
      " \"Afterlife\" "

  Spec.it s "Hideaway" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Hideaway
      " \"Hideaway\" "

  Spec.it s "Dredge" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Dredge
      " \"Dredge\" "

  Spec.it s "Soulshift" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Soulshift
      " \"Soulshift\" "

  Spec.it s "Ninjutsu" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Ninjutsu
      " \"Ninjutsu\" "

  Spec.it s "Bloodthirst" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Bloodthirst
      " \"Bloodthirst\" "

  Spec.it s "Tribute" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Tribute
      " \"Tribute\" "

  Spec.it s "Reinforce" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Reinforce
      " \"Reinforce\" "

  Spec.it s "Ripple" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Ripple
      " \"Ripple\" "

  Spec.it s "Annihilator" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Annihilator
      " \"Annihilator\" "

  Spec.it s "Mobilize" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Mobilize
      " \"Mobilize\" "

  Spec.it s "Firebending" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Firebending
      " \"Firebending\" "

  Spec.it s "Unearth" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Unearth
      " \"Unearth\" "

  Spec.it s "Embalm" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Embalm
      " \"Embalm\" "

  Spec.it s "Eternalize" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Eternalize
      " \"Eternalize\" "

  Spec.it s "LevelUp" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.LevelUp
      " \"LevelUp\" "

  Spec.it s "Outlast" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Outlast
      " \"Outlast\" "

  Spec.it s "Crew" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Crew
      " \"Crew\" "

  Spec.it s "Saddle" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Saddle
      " \"Saddle\" "

  Spec.it s "Fabricate" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Fabricate
      " \"Fabricate\" "

  -- CR 702.168a: the family CR 702.168d and CR 701.58d both name, "a face-down
  -- permanent you control with a disguise ability".
  Spec.it s "Disguise" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Disguise
      " \"Disguise\" "

  Spec.it s "Ward" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Ward
      " \"Ward\" "

  Spec.it s "Rampage" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Rampage
      " \"Rampage\" "

  Spec.it s "Frenzy" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Frenzy
      " \"Frenzy\" "

  Spec.it s "Afflict" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Afflict
      " \"Afflict\" "

  Spec.it s "MoreThanMeetsTheEye" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.MoreThanMeetsTheEye
      " \"MoreThanMeetsTheEye\" "

  Spec.it s "Toxic" $
    Common.assertCodec
      s
      KeywordFamily.codec
      KeywordFamily.Toxic
      " \"Toxic\" "

  -- The family tag and the written instance's tag share a name and must stay
  -- distinguishable on the wire: `"Toxic"` is CR 702.164's ability and
  -- `{"type":"Toxic","value":2}` is what a card prints. Pinned here rather than
  -- left to the Filter arms, since this is a property of the two keyword codecs
  -- and not of the atoms that carry them.
  Spec.it s "the family tag is not the instance's tag" $
    Spec.assertBool
      s
      (Codec.encode KeywordFamily.codec KeywordFamily.Toxic /= Common.tagged "Toxic" (Just (Value.integer 2)))
      "the toxic family is not toxic 2"

  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s KeywordFamily.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s KeywordFamily.codec
