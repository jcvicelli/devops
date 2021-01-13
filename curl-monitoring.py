# pip3 install requests, slackclient
import requests
import sys
import os
from slack import WebClient
from slack.errors import SlackApiError


def main():

    print("Starting...")

    filepath = 'sites.list'
    with open(filepath) as fp:
        for cnt, line in enumerate(fp):

            try:
                response = requests.head(line.rstrip())

                if (response.status_code == requests.codes.ok):
                    print("Check {}: {} OK!".format(cnt, line.rstrip()))
                else:
                    print("Check {}: {} ERROR {}".format(
                        cnt, line.rstrip(), response.status_code))
                    slack_message_send(line.rstrip())

            except:
                print("Unexpected error:", sys.exc_info()[0], line.rstrip())
                slack_message_send(line.rstrip())


def slack_message_send(url_message):

    slack_token = os.environ["SLACK_API_TOKEN"]
    client = WebClient(token=slack_token)

    try:
        slack_response = client.chat_postMessage(
            channel="#monitoring",
            text=url_message + " is offline! :fire:"
        )
    except SlackApiError as e:
        # You will get a SlackApiError if "ok" is False
        # str like 'invalid_auth', 'channel_not_found'
        assert e.slack_response["error"]


if __name__ == '__main__':
    main()
