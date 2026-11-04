module Parun.Extra.Parsec where

import qualified Data.Text as Text
import qualified Parun.Extra.Either as Either
import qualified Text.Parsec as Parsec
import qualified Text.Parsec.Error as Error
import qualified Text.Parsec.Pos as Pos
import qualified Text.Parsec.Prim as Prim

-- | Attempts to parse the string using the given parser.
parseString :: Parsec.Parsec String () a -> String -> Maybe a
parseString p = Either.hush . Parsec.parse p ""

-- | Attempts to parse the string, as text, using the given parser.
parseText :: Parsec.Parsec Text.Text () a -> String -> Maybe a
parseText p = Either.hush . Parsec.parse p "" . Text.pack

-- | Consumes the longest prefix whose characters all satisfy the predicate, in
-- one step rather than a character at a time, keeping the source position
-- exact. Never fails; an empty match consumes nothing.
takeWhile :: (Char -> Bool) -> Parsec.Parsec Text.Text u Text.Text
takeWhile p = Prim.mkPT $ \state ->
  let (match, rest) = Text.span p (Prim.stateInput state)
   in pure $
        if Text.null match
          then Prim.Empty . pure $ Prim.Ok match state (Prim.unknownError state)
          else
            let position = Text.foldl' Pos.updatePosChar (Prim.statePos state) match
             in Prim.Consumed . pure $
                  Prim.Ok match state {Prim.stateInput = rest, Prim.statePos = position} (Error.newErrorUnknown position)
