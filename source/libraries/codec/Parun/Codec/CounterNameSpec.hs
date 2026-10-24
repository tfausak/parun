module Parun.Codec.CounterNameSpec where

import qualified Data.Either as Either
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.CounterName as CounterName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterKindFamily as CounterKindFamily
import qualified Parun.Types.CounterName as CounterName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterName" $ do
  Spec.it s "UnsafeMkCounterName" $
    Common.assertCodec
      s
      CounterName.codec
      (CounterName.UnsafeMkCounterName (Text.pack "conqueror"))
      " \"conqueror\" "

  -- CR 122.1: the name IS the identity, so nothing folds case or punctuation.
  -- Two spellings a normalization would merge stay two kinds.
  Spec.it s "UnsafeMkCounterName, a name that differs only in case" $
    Common.assertCodec
      s
      CounterName.codec
      (CounterName.UnsafeMkCounterName (Text.pack "Conqueror"))
      " \"Conqueror\" "

  Spec.it s "has a schema" $
    Common.assertHasSchema s CounterName.codec

  Spec.it s "rejects a non-string" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " 1 ") >>= Codec.decode CounterName.codec))
      "expected a decode failure"

  -- CR 122.1's interchangeability sentence: a name Parun.Types.CounterKind
  -- already has a constructor for would key the same rules object twice.
  Spec.it s "rejects a reserved spelling" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " \"shield\" ") >>= Codec.decode CounterName.codec))
      "expected a decode failure"

  -- CR 122.1b's keyword counters: a card writing "flying" names the kind
  -- CounterKind.Keyword Flying already is, whatever keyword the payload carries.
  Spec.it s "rejects a CR 122.1b keyword spelling" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " \"vigilance\" ") >>= Codec.decode CounterName.codec))
      "expected a decode failure"

  Spec.it s "rejects the empty name" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " \"\" ") >>= Codec.decode CounterName.codec))
      "expected a decode failure"

  -- The runtime half of what forces CounterName.reserved. The compile-time half
  -- is CounterName.familyOf's and CounterName.spellings' exhaustiveness, which
  -- a new Parun.Types.CounterKind constructor breaks; this catches the arm that
  -- compiles but reserves nothing. CounterKindFamily.Named is one arm allowed to
  -- answer nothing: its spellings are what the check reads. PowerToughness is
  -- the other: CR 122.1a's +X/+Y spellings are an open set, rejected by pattern
  -- (the case after this one).
  Spec.it s "every counter kind but the named one reserves a spelling" $
    Spec.assertBool
      s
      ( all
          ( \family ->
              if family == CounterKindFamily.Named || family == CounterKindFamily.PowerToughness
                then Set.null (CounterName.spellings family)
                else
                  -- The subset conjunct is tautological given CounterName.reserved's
                  -- definition (foldMap spellings over this same enumeration) --
                  -- it cannot fail under any mutation of spellings. It pins that
                  -- DEFINITION instead: it would redden if reserved were rewritten
                  -- to something other than the full fold. The null check beside
                  -- it is the one with force, tripping a lazy `-> Set.empty` arm.
                  not (Set.null (CounterName.spellings family))
                    && Set.isSubsetOf (CounterName.spellings family) CounterName.reserved
          )
          [minBound .. maxBound]
      )
      "expected every kind's spelling to be reserved"

  -- CR 122.1a: a +X/+Y spelling is CounterKind.powerToughness's whatever the
  -- numbers, so a card cannot name one; a name merely containing a slash can.
  Spec.it s "rejects a CR 122.1a +X/+Y spelling" $ do
    Spec.assertBool
      s
      (all (Either.isLeft . CounterName.make . Text.pack) ["+2/+0", "+0/+2", "-0/-2", "+10/+10"])
      "expected each +X/+Y spelling rejected"
    Spec.assertBool
      s
      (all (Either.isRight . CounterName.make . Text.pack) ["2/0", "+2/", "w/+2"])
      "expected a name that is not +X/+Y accepted"

  -- Pairs each family with a kind that has it, so CounterName.familyOf answers
  -- for every constructor rather than for the two the cases above happen to
  -- reach. Both payload-carrying arms are here: CR 122.1b's keyword counter
  -- drops its keyword, and CR 122.1's named counter drops its name.
  Spec.it s "every family names a counter kind" $
    Spec.assertBool
      s
      (all (\family -> CounterName.familyOf (representative family) == family) [minBound .. maxBound])
      "expected familyOf to answer each family"

-- | One 'CounterKind.CounterKind' per family, for the case above.
representative :: CounterKindFamily.CounterKindFamily -> CounterKind.CounterKind ()
representative family = case family of
  CounterKindFamily.PlusOnePlusOne -> CounterKind.PlusOnePlusOne
  CounterKindFamily.MinusOneMinusOne -> CounterKind.MinusOneMinusOne
  CounterKindFamily.Keyword -> CounterKind.Keyword ()
  CounterKindFamily.Loyalty -> CounterKind.Loyalty
  CounterKindFamily.Lore -> CounterKind.Lore
  CounterKindFamily.Defense -> CounterKind.Defense
  CounterKindFamily.Time -> CounterKind.Time
  CounterKindFamily.Fade -> CounterKind.Fade
  CounterKindFamily.Age -> CounterKind.Age
  CounterKindFamily.Shield -> CounterKind.Shield
  CounterKindFamily.Finality -> CounterKind.Finality
  CounterKindFamily.Stun -> CounterKind.Stun
  CounterKindFamily.Level -> CounterKind.Level
  CounterKindFamily.Hone -> CounterKind.Hone
  CounterKindFamily.PowerToughness -> CounterKind.powerToughness 2 0
  CounterKindFamily.Named -> CounterKind.Named (CounterName.UnsafeMkCounterName (Text.pack "conqueror"))
