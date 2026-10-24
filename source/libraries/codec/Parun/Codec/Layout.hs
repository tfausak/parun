module Parun.Codec.Layout where

import qualified Parun.Codec.CardName as CardName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Layout as Layout

codec :: Codec.Codec Layout.Layout
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Normal" Layout.Normal,
      Arm.nullary "Split" Layout.Split,
      Arm.nullary "Room" Layout.Room,
      Arm.nullary "Flip" Layout.Flip,
      Arm.nullary "Adventure" Layout.Adventure,
      Arm.nullary "Omen" Layout.Omen,
      Arm.nullary "Preparation" Layout.Preparation,
      Arm.nullary "Transforming" Layout.Transforming,
      Arm.nullary "ModalDoubleFaced" Layout.ModalDoubleFaced,
      Arm.payload "Meld" CardName.codec Layout.Meld (\x -> case x of Layout.Meld y -> Just y; _ -> Nothing)
    ]

tagOf :: Layout.Layout -> String
tagOf x = case x of
  Layout.Normal -> "Normal"
  Layout.Split -> "Split"
  Layout.Room -> "Room"
  Layout.Flip -> "Flip"
  Layout.Adventure -> "Adventure"
  Layout.Omen -> "Omen"
  Layout.Preparation -> "Preparation"
  Layout.Transforming -> "Transforming"
  Layout.ModalDoubleFaced -> "ModalDoubleFaced"
  Layout.Meld {} -> "Meld"
