#!/usr/bin/env bash

#
# SPDX-FileCopyrightText: 2021-2024 Nextcloud GmbH and Nextcloud contributors
# SPDX-FileCopyrightText: 2021 Andy Scherzinger <info@andy-scherzinger.de>
# SPDX-License-Identifier: GPL-3.0-or-later
#

#1: LOG_USERNAME
#2: LOG_PASSWORD
#3: DRONE_BUILD_NUMBER
#4: DRONE_PULL_REQUEST
#5: GITHUB_TOKEN

PUBLIC_URL=https://www.kaminsky.me/nc-dev/android-artifacts
USER=$1
PASS=$2
BUILD=$3
PR=$4
GITHUB_TOKEN=$5
DAV_URL=https://nextcloud.kaminsky.me/remote.php/dav/files/$USER/android-artifacts/

if ! test -e app/build/outputs/apk/qa/debug/app-qa-*.apk ; then
    exit 1
fi
echo "Uploaded artifact to $DAV_URL/$BUILD-talk.apk"

# delete all old comments, starting with "APK file:"
oldComments=$(curl 2>/dev/null --header "authorization: Bearer $GITHUB_TOKEN" -X GET https://api.github.com/repos/nextcloud/talk-android/issues/$PR/comments | jq '.[] | (.id |tostring) + "|" + (.user.login | test("github-actions") | tostring) + "|" + (.body | test("APK file:.*") | tostring)'  | grep "true|true" | tr -d "\"" | cut -f1 -d"|")

echo $oldComments | while read comment ; do
    curl 2>/dev/null --header "authorization: Bearer $GITHUB_TOKEN" -X DELETE https://api.github.com/repos/nextcloud/talk-android/issues/comments/$comment
done

apt-get -y install qrencode

qrencode -o $PR.png "$PUBLIC_URL/$BUILD-talk.apk"

curl -u $USER:$PASS -X PUT $DAV_URL/$BUILD-talk.apk --upload-file app/build/outputs/apk/qa/debug/app-qa-*.apk
curl -u $USER:$PASS -X PUT $DAV_URL/$BUILD-talk.png --upload-file $PR.png
curl --header "authorization: Bearer $GITHUB_TOKEN" -X POST https://api.github.com/repos/nextcloud/talk-android/issues/$PR/comments -d "{ \"body\" : \"APK file: $PUBLIC_URL/$BUILD-talk.apk <br/><br/> ![qrcode]($PUBLIC_URL/$BUILD-talk.png) <br/><br/>To test this change/fix you can simply download above APK file and install and test it in parallel to your existing Nextcloud Talk app. \" }"
