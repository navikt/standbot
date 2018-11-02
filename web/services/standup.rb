# frozen_string_literal: true

def run_standup(client, teams)
  logger.info('Running daily stand-up')
  notified = []

  teams.each do |team|
    logger.info("Stand-up for team #{team.name}")

    team.members.each do |member|
      if member.vacation?
        logger.info("#{member.full_name} is on vacation")
        next
      end

      im = client.im_open(user: member.slack_id)
      im_channel_id = im && im['channel'] && im['channel']['id']
      next unless im_channel_id

      if notified.include?(member.full_name)
        logger.info("#{member.full_name} is already notified, skipping this time")
        next
      end

      logger.info("Notifying #{member.full_name}")
      message = "Tid for stand-up!\nRapporter tilbake med "
      message += '`i går`, ' unless Date.today.monday?
      message += "`i dag`, og `problem`.\n"

      message += if member.teams.size > 1
                   'Du er med i flere team, og må da spesifisere team '\
                   'i rapporten din. Alt du trenger å gjøre er '\
                   "å starte kommandoen din med  #teamnavn.\n"\
                   'For eksempel: `#aura i dag er jeg på kotlin workshop`'\
                   "\nDu er medlem i følgende teams: #{member.teams.map(&:name).join(', ')}\n"
                 else
                   "For eksempel: `i går satt jeg i møter hele dagen`.\n"\
                   "Se team-rapporten på https://standup.nais.io/team/#{team.name}\n"
                 end
      message += 'Hvis du ikke ønsker å melde deg av standup, skriv `meld av`'

      client.chat_postMessage(text: message, channel: im_channel_id, as_user: true)
      notified.append(member.full_name)
    rescue Slack::Web::Api::Errors::SlackError => e
      logger.error("Problem running stand-up for #{member.full_name}: #{e}")
    end
  end
end
