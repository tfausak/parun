module Parun.Codec.SubtypeSpec where

import qualified Parun.Codec.Subtype as Subtype
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Subtype as Subtype

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Subtype" $ do
  Spec.it s "Mountain" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Mountain
      " \"Mountain\" "
  Spec.it s "Swamp" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Swamp
      " \"Swamp\" "
  Spec.it s "Forest" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Forest
      " \"Forest\" "
  Spec.it s "Island" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Island
      " \"Island\" "
  Spec.it s "Plains" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Plains
      " \"Plains\" "
  Spec.it s "Goblin" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Goblin
      " \"Goblin\" "
  Spec.it s "Warrior" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Warrior
      " \"Warrior\" "
  Spec.it s "Human" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Human
      " \"Human\" "
  Spec.it s "Bird" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Bird
      " \"Bird\" "
  Spec.it s "Ogre" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Ogre
      " \"Ogre\" "
  Spec.it s "Centaur" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Centaur
      " \"Centaur\" "
  Spec.it s "Cat" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Cat
      " \"Cat\" "
  Spec.it s "Dinosaur" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Dinosaur
      " \"Dinosaur\" "
  Spec.it s "Beast" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Beast
      " \"Beast\" "
  Spec.it s "Rat" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Rat
      " \"Rat\" "
  Spec.it s "Elephant" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Elephant
      " \"Elephant\" "
  Spec.it s "Myr" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Myr
      " \"Myr\" "
  Spec.it s "Skeleton" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Skeleton
      " \"Skeleton\" "
  Spec.it s "Wall" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Wall
      " \"Wall\" "
  Spec.it s "Wizard" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Wizard
      " \"Wizard\" "
  Spec.it s "Shapeshifter" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Shapeshifter
      " \"Shapeshifter\" "
  Spec.it s "Lhurgoyf" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Lhurgoyf
      " \"Lhurgoyf\" "
  Spec.it s "Arcane" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Arcane
      " \"Arcane\" "
  Spec.it s "Barbarian" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Barbarian
      " \"Barbarian\" "
  Spec.it s "Zombie" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Zombie
      " \"Zombie\" "
  Spec.it s "Fungus" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Fungus
      " \"Fungus\" "
  Spec.it s "Elemental" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Elemental
      " \"Elemental\" "
  Spec.it s "Rogue" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Rogue
      " \"Rogue\" "
  Spec.it s "Hag" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Hag
      " \"Hag\" "
  Spec.it s "Warlock" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Warlock
      " \"Warlock\" "
  Spec.it s "Soldier" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Soldier
      " \"Soldier\" "
  Spec.it s "Phyrexian" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Phyrexian
      " \"Phyrexian\" "
  Spec.it s "Elf" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Elf
      " \"Elf\" "
  Spec.it s "Nightmare" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Nightmare
      " \"Nightmare\" "
  Spec.it s "Horse" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Horse
      " \"Horse\" "
  Spec.it s "Aura" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Aura
      " \"Aura\" "
  Spec.it s "Equipment" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Equipment
      " \"Equipment\" "
  Spec.it s "Scout" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Scout
      " \"Scout\" "
  Spec.it s "Artificer" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Artificer
      " \"Artificer\" "
  Spec.it s "Troll" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Troll
      " \"Troll\" "
  Spec.it s "Nomad" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Nomad
      " \"Nomad\" "
  Spec.it s "Shaman" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Shaman
      " \"Shaman\" "
  Spec.it s "Demon" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Demon
      " \"Demon\" "
  Spec.it s "Cleric" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Cleric
      " \"Cleric\" "
  Spec.it s "Illusion" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Illusion
      " \"Illusion\" "
  Spec.it s "Spirit" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Spirit
      " \"Spirit\" "
  Spec.it s "Angel" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Angel
      " \"Angel\" "
  Spec.it s "Insect" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Insect
      " \"Insect\" "
  Spec.it s "Berserker" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Berserker
      " \"Berserker\" "
  Spec.it s "Thopter" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Thopter
      " \"Thopter\" "
  Spec.it s "Dragon" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Dragon
      " \"Dragon\" "
  Spec.it s "Unicorn" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Unicorn
      " \"Unicorn\" "
  Spec.it s "Curse" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Curse
      " \"Curse\" "
  Spec.it s "Desert" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Desert
      " \"Desert\" "
  Spec.it s "Faerie" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Faerie
      " \"Faerie\" "
  Spec.it s "Rhino" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Rhino
      " \"Rhino\" "
  Spec.it s "Jace" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Jace
      " \"Jace\" "
  Spec.it s "Wraith" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Wraith
      " \"Wraith\" "
  Spec.it s "Golem" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Golem
      " \"Golem\" "
  Spec.it s "Turtle" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Turtle
      " \"Turtle\" "
  Spec.it s "Mongoose" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Mongoose
      " \"Mongoose\" "
  Spec.it s "Frog" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Frog
      " \"Frog\" "
  Spec.it s "Vampire" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Vampire
      " \"Vampire\" "
  Spec.it s "Dryad" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Dryad
      " \"Dryad\" "
  Spec.it s "Knight" $
    Common.assertCodec
      s
      Subtype.codec
      Subtype.Knight
      " \"Knight\" "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Subtype.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s Subtype.codec
