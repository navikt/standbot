import re

from datetime import datetime
from models import Team

SLACK_TEAM = r"\<#[A-Z0-9]{,9}\|(\w+)\>"
LITERAL_TEAM = r"#(\w+)"

def _clean_team_name(name):
    matches = re.search(SLACK_TEAM, name)
    if matches:
        return matches.group(1)

    matches = re.search(LITERAL_TEAM, name)
    if matches:
        return matches.group(1)

    return name


def set_default_team(team_name, member):
    if team_name is None:
        response = 'Du er medlem av følgende team(s): {}'.format(
            ', '.join([t.name for t in member.teams()]))
        if member.team_id:
            response += '\nDitt standard team er `{}`'.format(member.team.name)
        return response

    if team_name in ['clear', 'tøm']:
        member.team_id = None
        member.updated_at = datetime.now()
        member.save()
        return 'Standard team er fjernet'

    team_name = _clean_team_name(team_name)
    team = Team.get_or_none(Team.name == team_name)
    if team is None:
        return 'Finner ikke team `{}`'.format(team_name)

    if team.has_member(member):
        member.team_id = team.id
        member.updated_at = datetime.now()
        member.save()
        return 'Nytt standard team er satt til `{}`'.format(team.name)

    return 'Du er ikke medlem av `{}`'.format(team.name)
