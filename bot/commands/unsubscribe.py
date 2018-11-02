from models import Membership, Team
from commands.team import _clean_team_name

def unsubscribe(team_name, member):
    if len(member.teams()) == 0:
        return 'Du er ikke medlem av noen team'

    if len(member.teams()) > 1 and not team_name:
        return 'Du må spesifisere team, `meld av <team>`'

    team = None
    if team_name:
        team_name = _clean_team_name(team_name)
        team = Team.get_or_none(Team.name == team_name)

        if team is None:
            return 'Finner ikke team `{}`'.format(team_name)

        if not team.has_member(member):
            return 'Du er ikke medlem av `{}`'.format(team.name)
    else:
        team = member.teams()[0]

    Membership.delete().where(Membership.member == member.id).where(Membership.team == team.id).execute()

    if member.team_id == team.id:
        member.team_id = None
        member.save()

    return 'Du er nå avmeldt'
