module Parun.Json.Array where

import qualified Control.Monad as Monad
import qualified Data.ByteString.Builder as Builder
import qualified Data.Text as Text
import qualified Parun.Extra.Monoid as Monoid
import qualified Parun.Extra.Parsec as Parsec
import qualified Parun.Extra.Semigroup as Semigroup
import qualified Text.Parsec as Parsec

newtype Array a = MkArray
  { unwrap :: [a]
  }
  deriving (Eq, Ord, Show)

decode :: Parsec.Parsec Text.Text u a -> Parsec.Parsec Text.Text u (Array a)
decode p =
  fmap MkArray
    . Parsec.between (Parsec.char '[' <* decodeBlanks) (Parsec.char ']')
    $ Parsec.sepBy (p <* decodeBlanks) (Parsec.char ',' <* decodeBlanks)

decodeBlanks :: Parsec.Parsec Text.Text u ()
decodeBlanks = Monad.void . Parsec.takeWhile $ \c -> c == ' ' || c == '\t' || c == '\n' || c == '\r'

encode :: (a -> Builder.Builder) -> Array a -> Builder.Builder
encode b =
  Semigroup.around (Builder.charUtf8 '[') (Builder.charUtf8 ']')
    . Monoid.sepBy (Builder.charUtf8 ',')
    . fmap b
    . unwrap
