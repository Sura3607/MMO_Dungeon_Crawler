module Data.Queries.PlayerQuery where

getPlayerByName :: String -> IO (Maybe ())
getPlayerByName _ = return Nothing