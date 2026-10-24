module Parun.Codec.FromOutsideTheGameSpec where

import qualified Parun.Codec.FromOutsideTheGame as FromOutsideTheGame
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.FromOutsideTheGame as FromOutsideTheGame
import qualified Parun.Types.OutsideDestination as OutsideDestination

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
            FromOutsideTheGame.reveal = True
          }
      )
      " {\"count\":1,\"destination\":{\"type\":\"Hand\"},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Sorcery\"}},\"reveal\":true,\"upTo\":false} "
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
            FromOutsideTheGame.reveal = False
          }
      )
      " {\"count\":4,\"destination\":{\"type\":\"LibraryShuffled\"},\"filter\":{\"type\":\"And\",\"value\":[]},\"reveal\":false,\"upTo\":true} "
