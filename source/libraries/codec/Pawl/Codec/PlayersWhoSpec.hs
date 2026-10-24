module Pawl.Codec.PlayersWhoSpec where

import qualified Pawl.Codec.PlayersWho as PlayersWho
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.ControlMargin as ControlMargin
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.PlayersWho as PlayersWho

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.PlayersWho" $ do
  Spec.it s "MkPlayersWho, unnarrowed, and the key is omitted" $
    Common.assertCodec
      s
      PlayersWho.codec
      PlayersWho.MkPlayersWho {PlayersWho.players = PlayerRef.Relative PlayerRelation.You, PlayersWho.who = Nothing}
      " {\"players\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
  -- Disorder's "each player who controls a white creature".
  Spec.it s "MkPlayersWho, narrowed by a player filter" $
    Common.assertCodec
      s
      PlayersWho.codec
      PlayersWho.MkPlayersWho
        { PlayersWho.players = PlayerRef.Relative PlayerRelation.AnyPlayer,
          PlayersWho.who = Just (Filter.Controls (ControlMargin.AtLeast 1) (Filter.And [Filter.HasCardType CardType.Creature, Filter.HasColor Color.White]))
        }
      " {\"players\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}},\"who\":{\"type\":\"Controls\",\"value\":{\"filter\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"HasColor\",\"value\":{\"type\":\"White\"}}]},\"margin\":{\"type\":\"AtLeast\",\"value\":1}}}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PlayersWho.codec
