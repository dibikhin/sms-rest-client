# encoding: utf-8

require './sms-rest-client.rb'

login, password = 'логин', 'пароль'
source_address, destination_address = 'адрес отправителя', 'адрес получателя'
text = 'Отправка работает.'

known_message_id = 'Идентификатор известного сообщения' # WF3F22A2E

# Период запроса статистики; даты в формате '2012-04-01 00:00:00'
now = Time.now
start_date = Time.mktime(now.year, now.month, 1).strftime('%F %T')
end_date = now.strftime('%F %T')

# Время отправки с учетом часового пояса получателя, в формате '2012-04-01T00:00:00'
sending_time = (Time.now + 30).strftime('%FT%T')

begin
  client = SmsRestClient.new(login, password)
rescue RestClient::Forbidden => e
  puts 'Не удалось авторизовать пользователя.'
  puts "Код ответа '%s'." % [e.message]
  exit!
end

session_id = client.session_id
balance_before = client.get_user_balance

message_id = client.send_sms(source_address, destination_address, text)
message_ids = client.send_sms_bulk(source_address, [destination_address, destination_address], text)
timezoned_message_id = client.send_sms_by_timezone(source_address, destination_address, text, sending_time)

balance_after = client.get_user_balance

stats = client.get_sms_statistics(start_date, end_date)
state = client.get_sms_state(known_message_id)

puts 'Идентификатор сессии ' + session_id
puts 'Ваш баланс до отправки сообщений ' + balance_before
puts 'Идентификаторы частей отправленного сообщения ' + message_id
puts 'Отправка с учетом часового пояса получателя:'
puts "  время отправки %s, идентификаторы частей сообщения %s" % [sending_time, timezoned_message_id]
puts "Идентификаторы частей сообщений массовой отправки: " + message_ids
puts 'Ваш баланс после отправки сообщений ' + balance_after
puts "Статус сообщения c идентификатором %s - '%s', цена %s" % [known_message_id, state['StateDescription'], state['Price']] 
puts "Статистика доставки с %s по %s:\n%s" % [start_date, end_date, stats]
