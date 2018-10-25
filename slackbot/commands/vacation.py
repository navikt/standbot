from datetime import datetime

def _parse_date(date_string):
    try:
        return datetime.strptime(date_string, "%d%m%y")
    except ValueError:
        return None

def _print_vacation_time(member):
    if member.vacation_from or member.vacation_to:
        return 'Det er registrert at du har ferie fra {:%d, %b %Y} til {:%d, %b %Y}'.format(
            member.vacation_from, member.vacation_to)
    return 'Det er ikke registrert ferie på deg'


def vacation(message, member):
    if message is None:
        return _print_vacation_time(member)
        
    if message == 'ferdig':
        member.vacation_from = None
        member.vacation_to = None
        member.save()
        return 'Velkommen tilbake! Håper du hadde en fin ferie'

    from_string = None
    to_string = None
    if '-' in message:
        messages = message.split('-')
        from_string = messages[0].strip()
        to_string = messages[1].strip()
    else:
        to_string = message.strip()

    vacation_to = _parse_date(to_string)
    if vacation_to is None:
        return 'Ukjent datoformat, godkjent er DDMMYY: {}'.format(to_string)
    if datetime.now().date() > vacation_to.date():
        return 'Kan ikke registrere ferie i fortiden'

    if from_string:
        vacation_from = _parse_date(from_string)
        if vacation_from is None and from_string:
            return 'Ukjent datoformat, godkjent er DDMMYY: {}'.format(from_string)
    else:
        vacation_from = datetime.now()

    member.vacation_from = vacation_from
    member.vacation_to = vacation_to
    member.save()

    return _print_vacation_time(member)
