{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Lens
import Control.Monad
import Data.Aeson as A
import Data.Aeson.Lens
import qualified Data.HashMap.Lazy as HML
import Data.List
import qualified Data.Text as T
import Development.Shake
import Development.Shake.Classes
import Development.Shake.FilePath
import Development.Shake.Forward
import GHC.Generics (Generic)
import Slick

---Config-----------------------------------------------------------------------

siteMeta :: SiteMeta
siteMeta =
  SiteMeta
    { siteAuthor = "Alessandro Marrella",
      baseUrl = "https://alessandromarrella.com",
      siteTitle = "Alessandro Marrella. Welcome to my website!",
      twitterHandle = Just "amarrella",
      githubUser = Just "amarrella",
      linkedinHandle = Just "alessandromarrella"
    }

outputFolder :: FilePath
outputFolder = "docs/"

--Data models-------------------------------------------------------------------

withSiteMeta :: Value -> Value
withSiteMeta (Object obj) = Object $ HML.union obj siteMetaObj
  where
    Object siteMetaObj = toJSON siteMeta
withSiteMeta _ = error "only add site meta to objects"

data SiteMeta
  = SiteMeta
      { siteAuthor :: String,
        baseUrl :: String, -- e.g. https://example.ca
        siteTitle :: String,
        twitterHandle :: Maybe String, -- Without @
        githubUser :: Maybe String,
        linkedinHandle :: Maybe String
      }
  deriving (Generic, Eq, Ord, Show, ToJSON)

-- | Data for the index page
data IndexInfo
  = IndexInfo
      { posts :: [Post]
      }
  deriving (Generic, Show, FromJSON, ToJSON)

-- | Data for a blog post
data Post
  = Post
      { title :: String,
        author :: String,
        content :: String,
        url :: String,
        date :: String,
        image :: Maybe String
      }
  deriving (Generic, Eq, Show, FromJSON, ToJSON, Binary)

instance Ord Post where
  compare p1 p2 = compare (date p2) (date p1)

-- | given a list of posts this will a rss feed
buildFeed :: [Post] -> Action ()
buildFeed posts' = do
  let sorted = sort posts'
  feedT <- compileTemplate' "site/templates/feed.xml"
  let feedInfo = IndexInfo {posts = sorted}
      feed = T.unpack $ substitute feedT (withSiteMeta $ toJSON feedInfo)
  writeFile' (outputFolder </> "feed.xml") feed

-- | given a list of posts this will build a table of contents
buildIndex :: [Post] -> Action ()
buildIndex posts' = do
  let sorted = sort posts'
  indexT <- compileTemplate' "site/templates/index.html"
  let indexInfo = IndexInfo {posts = sorted}
      indexHTML = T.unpack $ substitute indexT (withSiteMeta $ toJSON indexInfo)
  writeFile' (outputFolder </> "index.html") indexHTML

-- | Find and build all posts
buildPosts :: Action [Post]
buildPosts = do
  pPaths <- getDirectoryFiles "." ["site/posts//*.md"]
  forP pPaths buildPost

-- | Load a post, process metadata, write it to output, then return the post object
-- Detects changes to either post content or template
buildPost :: FilePath -> Action Post
buildPost srcPath = cacheAction ("build" :: T.Text, srcPath) $ do
  liftIO . putStrLn $ "Rebuilding post: " <> srcPath
  postContent <- readFile' srcPath
  -- load post content and metadata as JSON blob
  postData <- markdownToHTML . T.pack $ postContent
  let postUrl = T.pack . dropDirectory1 $ srcPath -<.> "html"
      withPostUrl = _Object . at "url" ?~ String postUrl
  -- Add additional metadata we've been able to compute
  let fullPostData = withSiteMeta . withPostUrl $ postData
  template <- compileTemplate' "site/templates/post.html"
  writeFile' (outputFolder </> T.unpack postUrl) . T.unpack $ substitute template fullPostData
  convert fullPostData

-- | Copy all static files from the listed folders to their destination
copyStaticFiles :: Action ()
copyStaticFiles = do
  filepaths <- getDirectoryFiles "./site/" ["images//*", "css//*", "js//*"]
  void $ forP filepaths $ \filepath ->
    copyFileChanged ("site" </> filepath) (outputFolder </> filepath)

-- | Specific build rules for the Shake system
--   defines workflow to build the website
buildRules :: Action ()
buildRules = do
  allPosts <- buildPosts
  buildIndex allPosts
  buildFeed allPosts
  copyStaticFiles

main :: IO ()
main = do
  let shOpts = shakeOptions {shakeVerbosity = Chatty, shakeLintInside = ["site"]}
  shakeArgsForward shOpts buildRules
