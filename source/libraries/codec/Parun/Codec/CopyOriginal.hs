module Parun.Codec.CopyOriginal where

import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CopyOriginal as CopyOriginal

codec :: Codec.Codec CopyOriginal.CopyOriginal
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "OfObject" ObjectRef.codec CopyOriginal.OfObject (\x -> case x of CopyOriginal.OfObject y -> Just y; _ -> Nothing),
      Arm.payload "Named" CardName.codec CopyOriginal.Named (\x -> case x of CopyOriginal.Named y -> Just y; _ -> Nothing)
    ]

tagOf :: CopyOriginal.CopyOriginal -> String
tagOf x = case x of
  CopyOriginal.OfObject {} -> "OfObject"
  CopyOriginal.Named {} -> "Named"
