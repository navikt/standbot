def run_reminder(client, teams)
  logger.info('Daily reminder of stand-up')

  reminders = {}
  teams.each do |team|
    standup = Standup.find(team_id: team.id, Sequel.function(:date, :created_at) => Date.today)
    team.members.each do |member|
      next if standup&.members&.include?(member)
      next if member.vacation?
      reminders[member.full_name] ||= {}
      reminders[member.full_name]['teams'] ||= []
      reminders[member.full_name]['teams'] << team.name
      reminders[member.full_name]['slack_id'] = member.slack_id
    end
  end

  reminders.each do |full_name, reminder|
    im = client.im_open(user: reminder['slack_id'])
    im_channel_id = im && im['channel'] && im['channel']['id']
    next unless im_channel_id
    logger.info("Reminding #{full_name} of stand-up for #{reminder['teams'].join(', ')}")
    message = "En påminnelse om at du ikke har vært på stand-up i dag for #{reminder['teams'].join(', ')}"
    client.chat_postMessage(text: message, channel: im_channel_id, as_user: true)
    rescue Slack::Web::Api::Errors::SlackError => e
      logger.error("Problem running reminder for #{full_name}: #{e}")
  end
end
