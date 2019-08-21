# frozen_string_literal: true
require 'dotenv/load'
require 'discordrb'
require 'uri'

bot = Discordrb::Commands::CommandBot.new token: ENV['BOT_TOKEN'], prefix: ENV['PREFIX']

bot.command(:ping) do |event|
  m = event.respond('Pong!')
  m.edit "Pong! Time taken: #{Time.now - event.timestamp} seconds."
end

bot.command(:eval, help_available: false) do |event, *code|
  break unless event.user.id == ENV['EVAL_USER_ID'].to_i

  begin
    eval code.join(' ')
  rescue StandardError => e
    "An error occurred 😞```\n#{e.to_s}```"
  end
end

bot.message(containing: URI.regexp) do |event|
  changed_links = []

  URI.extract event.content, ['http', 'https'] do |uristr|
    uri = URI(uristr)

    case uri.host
    when 'drop.com', 'massdrop.com'
      qs = Hash[URI.decode_www_form(uri.query || '')]

      break if qs['mode'] == 'guest_open'

      qs['mode'] = 'guest_open'
      uri.query = URI.encode_www_form(qs)

    when /(\w+)\.m\.wikipedia\.org/
      uri.host = "#{$1}.wikipedia.org"

    else
      break
    end

    changed_links << uri.to_s
  end

  unless changed_links.empty?
    event.respond "Fixed those links for you:\n#{changed_links.join "\n"}"
  end
end

bot.run
