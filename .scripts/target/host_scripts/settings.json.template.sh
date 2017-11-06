#!/bin/bash
#
cat <<EOF
{
  "public": {

    "title": "Your site title",
    "tagline":"Your site tagline",

    "logoUrl": "https://placekitten.com/250/80",
    "logoHeight": "80",
    "logoWidth": "250",
    "faviconUrl": "/favicon.ico",

    "language": "en",
    "locale": "en",

    "twitterAccount": "foo",
    "facebookPage": "http://facebook.com/foo",

    "googleAnalyticsId":"123foo"

  },

  "defaultEmail": "hello@world.com",
  "mailUrl": "smtp://username%40yourdomain.mailgun.org:yourpassword123@smtp.mailgun.org:587/",

  "deploymentParametersIndexFile": "${HOME}/.vulcan/index.json",

  "oAuth": {
    "google": {
      "clientId": "${GOOGLE_CLIENT_ID}",
      "secret": "${GOOGLE_CLIENT_SECRET}"
    },
    "twitter": {
      "consumerKey": "${TWITTER_CONSUMER_KEY}",
      "secret": "${TWITTER_SECRET}"
    },
    "facebook": {
      "appId": "${FACEBOOK_APP_ID}",
      "secret": "${FACEBOOK_APP_SECRET}"
    }
  }
}
EOF
