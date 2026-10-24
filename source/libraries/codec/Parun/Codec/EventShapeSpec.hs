module Parun.Codec.EventShapeSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.EventShape as EventShape
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardArrivedIn as CardArrivedIn
import qualified Parun.Types.EventShape as EventShape
import qualified Parun.Types.MovedBetween as MovedBetween
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EventShape" $ do
  Spec.it s "MovedBetween" $
    -- CR 700.4's "dies": moved from the battlefield to a graveyard.
    Common.assertCodec
      s
      EventShape.codec
      (EventShape.MovedBetween (MovedBetween.MkMovedBetween Zone.Battlefield Zone.Graveyard))
      " {\"type\":\"MovedBetween\",\"value\":{\"from\":{\"type\":\"Battlefield\"},\"to\":{\"type\":\"Graveyard\"}}} "
  -- CR 603.6c's origin with no destination: a bare Zone.
  Spec.it s "MovedFrom" $
    Common.assertCodec
      s
      EventShape.codec
      (EventShape.MovedFrom Zone.Battlefield)
      " {\"type\":\"MovedFrom\",\"value\":{\"type\":\"Battlefield\"}} "
  -- CR 712.21e's second half: the destination, and the origins that do not
  -- count. Parun.Codec.CardArrivedInSpec covers the payload's own two shapes;
  -- this case is here for the tag the arm wraps it in.
  Spec.it s "CardArrivedIn" $
    Common.assertCodec
      s
      EventShape.codec
      (EventShape.CardArrivedIn (CardArrivedIn.MkCardArrivedIn {CardArrivedIn.to = Zone.Graveyard, CardArrivedIn.excluding = Set.singleton Zone.Battlefield}))
      " {\"type\":\"CardArrivedIn\",\"value\":{\"excluding\":[{\"type\":\"Battlefield\"}],\"to\":{\"type\":\"Graveyard\"}}} "
  -- CR 601.2i's cast: PAYLOADLESS, so the encoded form is the bare tag and a
  -- decoder that demanded a value would reject every card that names it.
  Spec.it s "SpellCast" $
    Common.assertCodec
      s
      EventShape.codec
      EventShape.SpellCast
      " {\"type\":\"SpellCast\"} "
  Spec.it s "SpellCastThisGame" $
    Common.assertCodec
      s
      EventShape.codec
      EventShape.SpellCastThisGame
      " {\"type\":\"SpellCastThisGame\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s EventShape.codec
