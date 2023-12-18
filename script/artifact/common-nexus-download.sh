#!/usr/bin/env bash

set -e;
# Sample usage:
# NEXUS_USER=username NEXUS_PASSWORD=password NEXUS_OBJECT_GROUP_ID=hu.icellmobilsoft.doc.client NEXUS_OBJECT_ARTIFACT_ID=document-client NEXUS_DOWNLOAD_OUTPUT_FILE=document-client.test.jar common-nexus-download.sh
#
# Parameters:
# NEXUS_USER # optional
# NEXUS_PASSWORD
NEXUS_REPOSITORY_URL=${NEXUS_REPOSITORY_URL:-"https://nexus.icellmobilsoft.hu"}
NEXUS_REPOSITORY=${NEXUS_REPOSITORY:-public}
NEXUS_OBJECT_GROUP_ID=${NEXUS_OBJECT_GROUP_ID:-test}
NEXUS_OBJECT_ARTIFACT_ID=${NEXUS_OBJECT_ARTIFACT_ID:-none}
NEXUS_OBJECT_EXTENSION=${NEXUS_OBJECT_EXTENSION:-jar}
# NEXUS_OBJECT_VERSION="1.21.0" # can be empty
# NEXUS_OBJECT_CLASSIFIER # empty at most because we dont need classified dependency usually
# DOWNLOAD_DIR
NEXUS_DOWNLOAD_OUTPUT_FILE_NAME=${NEXUS_DOWNLOAD_OUTPUT_FILE_NAME:-"$NEXUS_OBJECT_ARTIFACT_ID-$NEXUS_OBJECT_VERSION.$NEXUS_OBJECT_EXTENSION"}
NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1=${NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1:-"$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME.sha1"}

echo "NEXUS_REPOSITORY_URL=$NEXUS_REPOSITORY_URL"
echo "NEXUS_REPOSITORY=$NEXUS_REPOSITORY"
echo "NEXUS_USER=$NEXUS_USER"
echo "NEXUS_OBJECT_GROUP_ID=$NEXUS_OBJECT_GROUP_ID"
echo "NEXUS_OBJECT_ARTIFACT_ID=$NEXUS_OBJECT_ARTIFACT_ID"
echo "NEXUS_OBJECT_VERSION=$NEXUS_OBJECT_VERSION"
echo "NEXUS_OBJECT_EXTENSION=$NEXUS_OBJECT_EXTENSION"
echo "NEXUS_DOWNLOAD_OUTPUT_FILE_NAME=$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME"
echo "NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1=$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1"

# create the nexus API call
# https://help.sonatype.com/repomanager3/integrations/rest-and-integration-api/search-api#SearchAPI-SearchandDownloadAsset
API_DOWNLOAD_PATH="service/rest/v1/search/assets/download?sort=version"
PATH_PARAM_REPO="repository=$NEXUS_REPOSITORY"
PATH_PARAM_G="maven.groupId=$NEXUS_OBJECT_GROUP_ID"
PATH_PARAM_A="maven.artifactId=$NEXUS_OBJECT_ARTIFACT_ID"
PATH_PARAM_E="maven.extension=$NEXUS_OBJECT_EXTENSION"
PATH_PARAM_E_SHA1="maven.extension=$NEXUS_OBJECT_EXTENSION.sha1"
PATH_PARAM_V="maven.baseVersion=$NEXUS_OBJECT_VERSION"
# NEXUS_OBJECT_CLASSIFIER null check
if [ -z "$NEXUS_OBJECT_CLASSIFIER" ]; then
    # we are looking for empty classifiers by default
    PATH_PARAM_C="maven.classifier"
else
    PATH_PARAM_C="maven.classifier=$NEXUS_OBJECT_CLASSIFIER"
fi
NEXUS_API_DOWNLOAD_FILE_LAST="$API_DOWNLOAD_PATH&$PATH_PARAM_REPO&$PATH_PARAM_G&$PATH_PARAM_A&$PATH_PARAM_C&$PATH_PARAM_E"
NEXUS_API_DOWNLOAD_FILE_LAST_SHA1="$API_DOWNLOAD_PATH&$PATH_PARAM_REPO&$PATH_PARAM_G&$PATH_PARAM_A&$PATH_PARAM_C&$PATH_PARAM_E_SHA1"

# NEXUS_USER null check
if [ ! -z "$NEXUS_USER" ]; then
    # activate the basic auth if parameters has been set
    CURL_USER="-u $NEXUS_USER:$NEXUS_PASSWORD "
fi
# create curl call
CURL_OBJECT_LAST_DOWNLOAD="curl -L $CURL_USER -X GET ""$NEXUS_REPOSITORY_URL/$NEXUS_API_DOWNLOAD_FILE_LAST"" --output $DOWNLOAD_DIR/$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME"
CURL_OBJECT_LAST_DOWNLOAD_SHA1="curl -L $CURL_USER -X GET ""$NEXUS_REPOSITORY_URL/$NEXUS_API_DOWNLOAD_FILE_LAST_SHA1"" --output $DOWNLOAD_DIR/$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1"
CURL_OBJECT_VERSION_DOWNLOAD="curl -L $CURL_USER -X GET ""$NEXUS_REPOSITORY_URL/$NEXUS_API_DOWNLOAD_FILE_LAST&$PATH_PARAM_V"" --output $DOWNLOAD_DIR/$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME"
CURL_OBJECT_VERSION_DOWNLOAD_SHA1="curl -L $CURL_USER -X GET ""$NEXUS_REPOSITORY_URL/$NEXUS_API_DOWNLOAD_FILE_LAST_SHA1&$PATH_PARAM_V"" --output $DOWNLOAD_DIR/$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1"

# NEXUS_OBJECT_VERSION null check
if [ -z "$NEXUS_OBJECT_VERSION" ]; then
    # get the last version (*-SNAPSHOT as usual)
    $CURL_OBJECT_LAST_DOWNLOAD
    $CURL_OBJECT_LAST_DOWNLOAD_SHA1
else
    # get the given version we need
    $CURL_OBJECT_VERSION_DOWNLOAD;
    $CURL_OBJECT_VERSION_DOWNLOAD_SHA1;
fi

FILE_SIZE=$(stat -c%s "$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME")
SHA1_FILE_SIZE=$(stat -c%s "$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1")
echo "$PWD/$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME file downloaded, size: $FILE_SIZE bytes."
echo "$PWD/$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1 file downloaded, size: $SHA1_FILE_SIZE bytes."

# checksum
SHA1_ORIGINAL=$(cat $DOWNLOAD_DIR/$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME_SHA1);
SHA1_FILE=$(sha1sum $DOWNLOAD_DIR/$NEXUS_DOWNLOAD_OUTPUT_FILE_NAME | awk '{print $1}')
if [ "$SHA1_ORIGINAL" = "$SHA1_FILE" ]; then
    echo "Checksum OK"
else
    echo "Corrupted file!"
    exit 1
fi
