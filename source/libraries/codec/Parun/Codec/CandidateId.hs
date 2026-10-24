module Parun.Codec.CandidateId where

import qualified Parun.Codec.FloatingCandidate as FloatingCandidate
import qualified Parun.Codec.PermanentCandidate as PermanentCandidate
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CandidateId as CandidateId

codec :: Codec.Codec CandidateId.CandidateId
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "OfPermanent" PermanentCandidate.codec CandidateId.OfPermanent (\x -> case x of CandidateId.OfPermanent y -> Just y; _ -> Nothing),
      Arm.payload "OfFloating" FloatingCandidate.codec CandidateId.OfFloating (\x -> case x of CandidateId.OfFloating y -> Just y; _ -> Nothing)
    ]

tagOf :: CandidateId.CandidateId -> String
tagOf x = case x of
  CandidateId.OfPermanent {} -> "OfPermanent"
  CandidateId.OfFloating {} -> "OfFloating"
