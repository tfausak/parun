module Parun.Codec.FromOutsideTheGameSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.FromOutsideTheGame as FromOutsideTheGame
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.DifferentIn as DifferentIn
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.FromOutsideTheGame as FromOutsideTheGame
import qualified Parun.Types.OutsideDestination as OutsideDestination
import qualified Parun.Types.OutsidePick as OutsidePick
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.FromOutsideTheGame" $ do
  -- CR 400.11c / 701.20a. Burning Wish's shape: a quality, and the reveal it
  -- prints.
  Spec.it s "MkFromOutsideTheGame, revealing" $
    Common.assertCodec
      s
      FromOutsideTheGame.codec
      ( FromOutsideTheGame.MkFromOutsideTheGame
          { FromOutsideTheGame.count = 1,
            FromOutsideTheGame.upTo = False,
            FromOutsideTheGame.destination = OutsideDestination.Hand,
            FromOutsideTheGame.filter = Filter.HasCardType CardType.Sorcery,
            FromOutsideTheGame.reveal = True,
            FromOutsideTheGame.differentIn = Set.empty,
            FromOutsideTheGame.pick = Nothing
          }
      )
      " {\"count\":1,\"destination\":\"Hand\",\"filter\":{\"type\":\"HasCardType\",\"value\":\"Sorcery\"},\"reveal\":true,\"upTo\":false} "
  -- Research's shape, and the pair is the point: every field differs from the
  -- case above, so a dropped count, upTo, reveal, filter or destination alike
  -- fails to round-trip. The empty And is CR 400.11c's
  -- "a card you own from outside the game" -- a quality that card does not state
  -- either, which admits everything.
  Spec.it s "MkFromOutsideTheGame, up to four, no reveal, no stated quality, and a shuffled library" $
    Common.assertCodec
      s
      FromOutsideTheGame.codec
      ( FromOutsideTheGame.MkFromOutsideTheGame
          { FromOutsideTheGame.count = 4,
            FromOutsideTheGame.upTo = True,
            FromOutsideTheGame.destination = OutsideDestination.LibraryShuffled,
            FromOutsideTheGame.filter = Filter.And [],
            FromOutsideTheGame.reveal = False,
            FromOutsideTheGame.differentIn = Set.empty,
            FromOutsideTheGame.pick = Nothing
          }
      )
      " {\"count\":4,\"destination\":\"LibraryShuffled\",\"filter\":{\"type\":\"And\",\"value\":[]},\"reveal\":false,\"upTo\":true} "
  -- Extrapolate the Impossible's shape: CR 201.2b's different names and an
  -- opponent's pick, the two defaulted keys written out.
  Spec.it s "MkFromOutsideTheGame, different names and an opponent's pick" $
    Common.assertCodec
      s
      FromOutsideTheGame.codec
      ( FromOutsideTheGame.MkFromOutsideTheGame
          { FromOutsideTheGame.count = 2,
            FromOutsideTheGame.upTo = False,
            FromOutsideTheGame.destination = OutsideDestination.Hand,
            FromOutsideTheGame.filter = Filter.And [],
            FromOutsideTheGame.reveal = True,
            FromOutsideTheGame.differentIn = Set.singleton DifferentIn.Names,
            FromOutsideTheGame.pick = Just (OutsidePick.MkOutsidePick PlayerRelation.Opponent 1)
          }
      )
      " {\"count\":2,\"destination\":\"Hand\",\"differentIn\":[\"Names\"],\"filter\":{\"type\":\"And\",\"value\":[]},\"pick\":{\"chooser\":\"Opponent\",\"count\":1},\"reveal\":true,\"upTo\":false} "
