# ℹ️ This script is meant as a template. Swap out parts that you don't need or
# want to adapt to your needs.

# Exit on error
set -e

# 📥 📥 📥 📥 📥 📥 📥
# REQUIREMENTS
#   git
#   heroku
#     Logged in and
#     With created Heroku project (see "heroku create"). Update the
#      HEROKU_PROJECT config (see below) to the correct app name.
#   jq
#   pushd & popd (should be built-in into all UNIX shells)
# 📥 📥 📥 📥 📥 📥 📥


# CONFIG
# ⚙️ ⚙️ ⚙️ ⚙️ ⚙️ ⚙️ ⚙️
# Change these to what you need
HEROKU_PROJECT=deploy-anything

BUILD_FOLDER=heroku_build
# 💡 Alternatively, create a temp folder
# BUILD_FOLDER=`mktemp -d`

# In case this script is not in the project root, change this line
PROJECT_ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Which files to copy is very project specific. Will be called inside the
# $BUILD_FOLDER. Use $BUILD_PATH for absolute path to $BUILD_FOLDER
copy_files () {
  STANDALONE_FOLDER="$PROJECT_ROOT/apps/next-app/.next/standalone"
  STATIC_FOLDER="$PROJECT_ROOT/apps/next-app/.next/static"
  PUBLIC_FOLDER="$PROJECT_ROOT/apps/next-app/public"

  echo " 📦 Copying standalone from $STANDALONE_FOLDER to $BUILD_PATH"
  cp -r "$STANDALONE_FOLDER/." "$BUILD_PATH"
  echo " 📦 Copying static from $STATIC_FOLDER to $BUILD_PATH"
  cp -r "$STATIC_FOLDER" "$BUILD_PATH/apps/next-app/.next"
  echo " 📦 Copying static from $STATIC_FOLDER to $BUILD_PATH"
  cp -r "$PUBLIC_FOLDER" "$BUILD_PATH/apps/next-app/"
}
# Same as above
setup_package_json () {
  SRC_PACKAGE_JSON="$PROJECT_ROOT/package.json"
  TARGET_PACKAGE_JSON="$BUILD_PATH/package.json"

  SRC_PNPM_LOCK="$PROJECT_ROOT/pnpm-lock.yaml"
  TARGET_PNPM_LOCK="$BUILD_PATH/pnpm-lock.yaml"

  echo " 📦 Remove devDependencies and override scripts"
  jq 'del(.devDependencies) | .scripts = { "start": "node apps/next-app/server.js" }' "$SRC_PACKAGE_JSON" > "$TARGET_PACKAGE_JSON"
  echo " 📦 Copy & repair pnpm-lock.yaml"
  cp "$SRC_PNPM_LOCK" "$TARGET_PNPM_LOCK"
  pnpm install --lockfile-only
}
# Customize the message to use for the commit in the Heroku repo.
build_commit_message () {
 echo "Deployment of commit $(cd $PROJECT_ROOT; git rev-parse HEAD)"
}
# ⚙️ ⚙️ ⚙️ ⚙️ ⚙️ ⚙️ ⚙️

# BUILDING
# 🛠️ 🛠️ 🛠️ 🛠️ 🛠️ 🛠️ 🛠️
echo "🛠️ Building app..."
echo 
nx build next-app
echo
echo "🛠️ Building app done"
echo
# 🛠️ 🛠️ 🛠️ 🛠️ 🛠️ 🛠️ 🛠️

# PACKAGE
# 📦 📦 📦 📦 📦 📦 📦
echo "📦 Packaging the app..."
echo
echo "📦 Clearing & creating folder" "$BUILD_FOLDER"
# Make sure the build folder is completely empty before we start
rm -rf "$BUILD_FOLDER"
mkdir "$BUILD_FOLDER"

# Convert relative path to absolute path
BUILD_PATH="$(cd "$BUILD_FOLDER"; pwd)"

# cd into the BUILD_PATH, but we'll use popd later
pushd "$BUILD_PATH" > /dev/null

echo "📦 Copying files to" "$BUILD_PATH"
copy_files
echo "📦 Files copied to" "$BUILD_PATH"

echo "📦 Setup dependencies & Heroku scripts..."
setup_package_json
echo "📦 Setup dependencies & Heroku scripts done"

popd > /dev/null

echo
echo "📦 Packaging the app done"
echo
# 📦 📦 📦 📦 📦 📦 📦

# DEPLOY
# 🚀 🚀 🚀 🚀 🚀 🚀 🚀
echo "🚀 Deploying app to Heroku..."
echo

# cd into the BUILD_PATH, but we'll use popd later
pushd "$BUILD_PATH" > /dev/null

echo "🚀 Initializing a new Git repo in $BUILD_PATH"
# Adding node_modules to .gitignore
echo "node_modules" > .gitignore
# Explicitly use "main" as branch name, in case the user setting has a different
# default branch.
git init -b main
heroku git:remote -a "$HEROKU_PROJECT"

echo "🚀 Pulling changes from Heroku"
git fetch heroku
# Set the git repository to heroku/main, without changing the local files
git reset --mixed heroku/main

echo "🚀 Committing changes to Heroku"
git add .
git commit -m "$(build_commit_message)"

echo "🚀 Pushing changes to Heroku..."
git push heroku main
echo "🚀 Pushing changes to Heroku done"

popd > /dev/null

echo
echo "🚀 Deploying app to Heroku done"
echo
# 🚀 🚀 🚀 🚀 🚀 🚀 🚀
