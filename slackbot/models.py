# Modellen blir definert i web-modulen (aka Ruby), og vi "importerer" kun det
# vi trenger i denne klassen. Derfor er de fleste modellene her ukomplette
# I Ruby/Rails så brukes det flertall i navn på databasemodeller. Siden peewee
# ikke bruker dette mønsteret, så bruker vi `Meta.table_name` for å overskrive
# klassenavnet.

import os

from datetime import datetime
from peewee import PostgresqlDatabase, CharField, ForeignKeyField, Model, DateTimeField, TextField

USER = os.getenv('POSTGRES_USER', 'postgres')
PASSWORD = os.getenv('POSTGRES_PASSWORD', 'postgres')
HOST = os.getenv('POSTGRES_SOCKET_PATH', 'localhost')

DB = PostgresqlDatabase('standbot', user=USER, password=PASSWORD, host=HOST, port='5432')

class BaseModel(Model):
    class Meta:
        database = DB

class Team(BaseModel):
    class Meta:
        table_name = 'teams'

    name = CharField()

    def has_member(self, member):
        query = (Team
                 .select()
                 .join(Membership)
                 .join(Member)
                 .where(Member.full_name == member.full_name)
                 .where(Team.name == self.name))
        return len(query) == 1

    def todays_standup(self):
        now = datetime.now()
        query = (Standup
                 .select()
                 .where(Standup.team_id == self.id)
                 .where(
                     (Standup.created_at.year == now.year) &
                     (Standup.created_at.month == now.month) &
                     (Standup.created_at.day == now.day)))
        return next(iter(query), None)

class Member(BaseModel):
    class Meta:
        table_name = 'members'

    full_name = CharField()
    slack_id = CharField()
    team = ForeignKeyField(Team)
    vacation_from = DateTimeField()
    vacation_to = DateTimeField()
    updated_at = DateTimeField()

    def teams(self):
        return (Team
                .select()
                .join(Membership)
                .join(Member)
                .where(Member.id == self.id))

    def todays_report(self, standup):
        now = datetime.now()
        query = (Report
                 .select()
                 .where(Report.standup_id == standup.id)
                 .where(Report.member_id == self.id)
                 .where(
                     (Report.created_at.year == now.year) &
                     (Report.created_at.month == now.month) &
                     (Report.created_at.day == now.day)))
        return next(iter(query), None)

class Membership(BaseModel):
    class Meta:
        table_name = 'memberships'

    member = ForeignKeyField(Member)
    team = ForeignKeyField(Team)

class Standup(BaseModel):
    class Meta:
        table_name = 'standups'

    team = ForeignKeyField(Team)
    created_at = DateTimeField()
    updated_at = DateTimeField()

class Report(BaseModel):
    class Meta:
        table_name = 'reports'

    member = ForeignKeyField(Member)
    standup = ForeignKeyField(Standup)
    today = TextField()
    yesterday = TextField()
    problem = TextField()
    created_at = DateTimeField()
    updated_at = DateTimeField()

def connect_to_db():
    if DB is None:
        DB.connect()

def close_db_connection():
    if DB:
        DB.close()
