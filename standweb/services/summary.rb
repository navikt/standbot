def run_summary(client, team)
  slack_channel = client.channels_list.channels.find { |channel| channel.name == team.channel.name }
  slack_channel ||= client.groups_list.groups.find { |channel| channel.name == team.channel.name }

  unless slack_channel
    Google::Cloud::ErrorReporting.report("Can't find channel #{team.channel.name} that #{team.name} uses") if ENV['RACK_ENV'] == 'production'
    logger.error("The channel ##{team.channel.name} doesn't exist")
    return
  end

  standup = team.todays_standup
  if standup.nil?
    logger.info("No stand-up to summaries for #{team.name}")
    return
  end

  attachments = []
  standup.reports.each do |report|
    text = ""
    text += "*I går:* #{report.yesterday}\n" if report.yesterday
    text += "_*I går:* #{report.yesterday_report.today}_\n" if report.yesterday_report && report.yesterday.nil?
    text += "*I dag:* #{report.today}\n" if report.today
    text += "*Problem:* #{report.problem}" if report.problem

    attachments <<
    {
      fallback: "fallback",
      author_name: report.member.full_name,
      author_icon: report.member.avatar_url,
      mrkdwn_in: [ "text" ],
      text: text,
      ts: report.created_at.to_i
    }
  end

  logger.info("Sending #{attachments.size} reports for #{team.name} with #{team.members.size} members")
  begin
    client.chat_postMessage(text: "Dagens rapport",
                            attachments: attachments,
                            channel: slack_channel.id,
                            as_user: true)
  rescue Slack::Web::Api::Errors::SlackError => e
    if e.response.body.error == 'not_in_channel'
      logger.warn("#{team.name} need to invite bot to channel")
      Google::Cloud::ErrorReporting.report("#{team.name} need to invite bot to channel") if ENV['RACK_ENV'] == 'production'
    end
  end
end
