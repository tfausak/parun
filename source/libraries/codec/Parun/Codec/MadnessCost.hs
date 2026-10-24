module Parun.Codec.MadnessCost where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Cost as Cost
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.MadnessCost as MadnessCost

-- | The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (MadnessCost.MadnessCost keyword)
codec keywordCodec =
  Arm.tagged
    tagOf
    [ Arm.payload "Stated" (Cost.codec keywordCodec) MadnessCost.Stated (\x -> case x of MadnessCost.Stated y -> Just y; _ -> Nothing),
      Arm.nullary "OwnManaCost" MadnessCost.OwnManaCost
    ]

tagOf :: MadnessCost.MadnessCost keyword -> String
tagOf x = case x of
  MadnessCost.Stated {} -> "Stated"
  MadnessCost.OwnManaCost {} -> "OwnManaCost"
