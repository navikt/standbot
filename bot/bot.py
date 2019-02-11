import logging
import os
import time
import re
from commands.team import set_default_team
from commands.standup import today, yesterday, problem
from commands.vacation import vacation
from commands.unsubscribe import unsubscribe
from flask import Flask
from slackclient import SlackClient
from threading import Thread
from models import Team, Member, connect_to_db, close_db_connection
from peewee import fn

if not os.getenv('GAE_ENV', '').startswith('standard'):
    from dotenv import load_dotenv
    load_dotenv()

SLACK_CLIENT = SlackClient(os.environ.get('SLACK_BOT_TOKEN'))
logger = logging.getLogger()
app = Flask(__name__)
threads = []

# constants
RTM_READ_DELAY = 0.2  # 1 second delay between reading from RTM
ALLOWED_COMMANDS = {'idag': today,
                    'i dag': today,
                    'igår': yesterday,
                    'i går': yesterday,
                    'problem': problem,
                    'team': set_default_team,
                    'ferie': vacation,
                    'meld av': unsubscribe}
DEFAULT_RESPONSE = "Ukjent kommando. Prøve en av *{}*.".format(
    ', '.join(ALLOWED_COMMANDS.keys()))

SLACK_TEAM = r"\<\#\w+\|\w+\>"
LITERAL_TEAM = r"\#?\w+"
TEAM_PARSE = r"(?P<team_name>{}|{})".format(SLACK_TEAM, LITERAL_TEAM)
COMMAND_PARSE = r"(?P<command>{})".format('|'.join(ALLOWED_COMMANDS))
MESSAGE_PARSE = r"(?P<message>.*)?"
PARSER = re.compile(r"({}\s)?{}(\s{})?".format(
    TEAM_PARSE, COMMAND_PARSE, MESSAGE_PARSE), re.IGNORECASE)


@app.route('/')
def hello():
    return 'Hello from the bot'


@app.route('/_ah/start')
def start():
    logger.info('Hello Google')
    if len(threads) == 0 or not threads[0].isAlive():
        thread = Thread(target=main)
        thread.start()
        threads.append(thread)
        return 'Thread has been started'
    return 'Thread is already running'


def parse_bot_commands(slack_events):
    for event in slack_events:
        if event["type"] == "message" and not ("subtype" in event or "bot_id" in event) and event["channel"].startswith("D"):
            command, message, team_name = parse_direct_mention(event["text"])
            return command, message, team_name, event
    return None, None, None, None


def parse_direct_mention(message_text):
    if message_text in ['help', 'hjelp']:
        return message_text, None, None

    matches = re.search(PARSER, message_text)
    if matches is None:
        return (None, None, None)

    team_name = matches.group('team_name')
    if team_name:
        team_name = team_name.split('|')[-1]
        team_name = re.sub(r'[#\>]', '', team_name)

    message = matches.group('message')
    if message:
        message = message.strip()

    return (matches.group('command').lower(), message, team_name)


def handle_command(command, message, team_name, event):
    if command in ['help', 'hjelp']:
        return 'Ikke implementert enda, ping <@U8PL7CR4K>'

    if command in ALLOWED_COMMANDS.keys():
        slack_id = event['user']
        member = Member.get_or_none(Member.slack_id == slack_id)
        if member is None:
            return 'Finner deg ikke i systemet, er du sikker på at du tilhører et team?'

        if command in ['ferie', 'team', 'meld av']:
            return ALLOWED_COMMANDS[command](message, member)

        team = None
        if len(member.teams()) > 1 or team_name:
            if team_name:
                team = Team.get_or_none(fn.lower(Team.name) == team_name.lower())
                if team is None:
                    return 'Finner ikke `{}` i systemet, har du skrevet riktig?'.format(team_name)
                if not team.has_member(member):
                    return 'Du er ikke medlem av `{}`'.format(team_name)
            elif member.team_id:
                team = member.team
            else:
                return 'Du er medlem av flere teams; {}\nSpesifieres med `#team-navn {} {}`'.format(
                    ', '.join([t.name for t in member.teams()]), command, message)
        else:
            team = member.teams()[0]

        return ALLOWED_COMMANDS[command](message, member, team)
    else:
        return None


def main():
    connect_to_db()
    if SLACK_CLIENT.rtm_connect(with_team_state=False):
        logger.info("Stand-up bot connected and running!")
        while True:
            command, message, team, event = parse_bot_commands(SLACK_CLIENT.rtm_read())

            if event:
                response = handle_command(command, message, team, event)
                # Sends the response back to the channel
                SLACK_CLIENT.api_call(
                    "chat.postMessage",
                    channel=event['channel'],
                    text=response or DEFAULT_RESPONSE)
            time.sleep(RTM_READ_DELAY)
    else:
        print("Connection failed. Exception traceback printed above.")
    close_db_connection()


if __name__ == '__main__':
    main()
