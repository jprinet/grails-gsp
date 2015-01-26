#!/bin/bash

grailsVersion="$(grep 'grailsVersion =' build.gradle | egrep -v ^[[:blank:]]*\/\/)"
grailsVersion="${grailsVersion#*=}"
grailsVersion="${grailsVersion//[[:blank:]\'\"]/}"

echo "Project Version: '$grailsVersion'"

EXIT_STATUS=0
./gradlew --stop
echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties
echo "Executing tests"
./gradlew --no-daemon --stacktrace test || EXIT_STATUS=$?
echo "Done."
echo "Executing integration tests"
./gradlew --no-daemon --stacktrace --info integrationTest < /dev/null || EXIT_STATUS=$?
echo "Done."


if [[ ( $TRAVIS_BRANCH == 'master' ) && $TRAVIS_REPO_SLUG == "grails/grails-core" && $TRAVIS_PULL_REQUEST == 'false' && $EXIT_STATUS -eq 0 ]]; then

    echo "Publishing archives"

    if [[ -n $TRAVIS_TAG ]]; then
        ./gradlew bintrayUpload || EXIT_STATUS=$?
        ./gradlew assemble || EXIT_STATUS=$?

        version="$TRAVIS_TAG"
        version=${version:1}
        zipName = "grails-$TRAVIS_TAG"
        zipName = ${zipName}.zip

        github-release release \
            --user grails \
            --repo grails-core \
            --tag $TRAVIS_TAG \
            --name "Grails $TRAVIS_TAG" \
            --description "The Grails Web Framework $TRAVIS_TAG" \
            --pre-release

        github-release upload \
            --user grails \
            --repo grails-core \
            --tag $TRAVIS_TAG \
            --name $zipName \
            --file "build/distributions/$zipName"
    else
        ./gradlew publish || EXIT_STATUS=$?
    fi

fi

exit $EXIT_STATUS
