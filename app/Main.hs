{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Monad.Logger
import qualified Data.Text.IO as Text
import Data.Time.Clock
import Database.Persist
import Database.Persist.Sqlite
import Network.Wai
import Network.Wai.Handler.Warp
import Relude
import Servant
import Servant.JS
import Servant.JS.Vanilla

import API
import Model

app :: Application
app = serve deckerAPI deckerServer

main :: IO ()
main = do
  putStrLn "# decker-engine"
  Text.writeFile "static/decker.js" $ jsForAPI jsAPI vanillaJS
  now <- getCurrentTime
  runSqlite "db/engine.db" $ do
    runMigration migrateAll
    p1 <- insert $ Person "person1"
    p2 <- insert $ Person "person2"
    insert $
      Comment
        "What is the purpose of this stuff? Nobody ever needs to know this."
        "cgg"
        "intro-slide"
        (Just p1)
        now
    insert $
      Comment "May I go to the bathroom?" "cgg" "intro-slide" (Just p1) now
    insert $ Comment "Wat?" "cgg" "intro-slide" (Just p2) now
    insert $
      Comment
        "Fucking hell, this is really anonymous! Keep on swearing."
        "cgg"
        "slide-2"
        Nothing
        now
  run 8081 app
