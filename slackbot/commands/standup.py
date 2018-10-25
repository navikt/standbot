from datetime import datetime
from models import Standup, Report

def _save_report(report_type, member, team, message):
    standup = team.todays_standup()
    if standup is None:
        standup = Standup(team_id=team.id)
        standup.created_at = datetime.now()
        standup.save()

    report = member.todays_report(standup)
    if report is None:
        report = Report(member_id=member.id, standup_id=standup.id)
        report.created_at = datetime.now()
        report.save()

    if report_type == 'today':
        report.today = message
    elif report_type == 'yesterday':
        report.yesterday = message
    elif report_type == 'problem':
        report.problem = message

    report.updated_at = datetime.now()
    report.save()

    standup.update_at = datetime.now()
    standup.save()

    return 'Rapportert til `{}`'.format(team.name)


def today(report, member, team):
    return _save_report('today', member, team, report)


def yesterday(report, member, team):
    return _save_report('yesterday', member, team, report)


def problem(report, member, team):
    return _save_report('problem', member, team, report)
