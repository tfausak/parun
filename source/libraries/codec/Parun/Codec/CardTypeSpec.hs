module Parun.Codec.CardTypeSpec where

import qualified Parun.Codec.CardType as CardType
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CardType" $ do
  Spec.it s "Artifact" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Artifact
      " \"Artifact\" "

  Spec.it s "Battle" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Battle
      " \"Battle\" "

  Spec.it s "Conspiracy" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Conspiracy
      " \"Conspiracy\" "

  Spec.it s "Creature" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Creature
      " \"Creature\" "

  Spec.it s "Dungeon" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Dungeon
      " \"Dungeon\" "

  Spec.it s "Enchantment" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Enchantment
      " \"Enchantment\" "

  Spec.it s "Instant" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Instant
      " \"Instant\" "

  Spec.it s "Kindred" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Kindred
      " \"Kindred\" "

  Spec.it s "Land" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Land
      " \"Land\" "

  Spec.it s "Phenomenon" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Phenomenon
      " \"Phenomenon\" "

  Spec.it s "Plane" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Plane
      " \"Plane\" "

  Spec.it s "Planeswalker" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Planeswalker
      " \"Planeswalker\" "

  Spec.it s "Scheme" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Scheme
      " \"Scheme\" "

  Spec.it s "Sorcery" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Sorcery
      " \"Sorcery\" "

  Spec.it s "Vanguard" $ do
    Common.assertCodec
      s
      CardType.codec
      CardType.Vanguard
      " \"Vanguard\" "

  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CardType.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s CardType.codec
