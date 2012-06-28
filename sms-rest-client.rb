# encoding: utf-8

require 'cgi'
require 'json'
require 'rest-client'

class SmsRestClient
  attr_reader :session_id
  
  Host = 'https://integrationapi.net/rest'
  
  def initialize(login, password)
    @login, @password = login, password
    @session_id = get_session_id
  end
  
  def get_user_balance
    execute { RestClient.get Host + '/User/Balance', { :params => { :sessionId => @session_id } } }
  end
  
  def send_sms(source_address, destination_address, text)
    params = { :sessionId => @session_id,
               :sourceAddress => source_address,
               :destinationAddress => destination_address,
               :data => text }
    result = execute { RestClient.post Host + '/Sms/Send', params }
    JSON.parse(result) * ', '
  end
  
  def send_sms_bulk(source_address, destination_addresses, data)
    params = { :sessionId => @session_id,
               :sourceAddress => source_address,
               :data => data }
    phones_param = destination_addresses.map { |phone| 'destinationAddresses=' + CGI.escape(phone) } * '&'
    result = execute { RestClient.post Host + '/Sms/SendBulk?' + phones_param, params }
    JSON.parse(result) * ', '
  end
  
  def send_sms_by_timezone(source_address, destination_address, text, send_date)
    params = { :sessionId => @session_id,
               :sourceAddress => source_address,
               :destinationAddress => destination_address,
               :data => text,
               :sendDate => send_date }
    result = execute { RestClient.post Host + '/Sms/SendByTimeZone', params }
    JSON.parse(result) * ', '
  end
  
  def get_sms_state(message_id)
    params = { :params => { :sessionId => @session_id, :messageId => message_id } }
    result = execute { RestClient.get Host + '/Sms/State', params }
    JSON.parse result
  end
  
  def get_sms_statistics(start_datetime, end_datetime)
    params = { :params => { :sessionId => @session_id,
                            :startDateTime => start_datetime,
                            :endDateTime => end_datetime } }
    result = execute { RestClient.get Host + '/Sms/Statistics', params }
    stats = JSON.parse result
    stats.map { |stat| stat * ': ' } * "\n"
  end
  
  def get_incoming_sms(start_datetime_utc, end_datetime_utc)
    params = { :params => { :sessionId => @session_id,
                            :minDateUTC => start_datetime_utc,
                            :maxDateUTC => end_datetime_utc } }
    result = execute { RestClient.get Host + '/Sms/In', params }
    stats = JSON.parse result
  end
  
  private
  def get_session_id
    params = { :params => { :login => @login, :password => @password } }
    result = RestClient.get Host + '/User/SessionId', params
    result.slice!(1..36)
  end
  
  def execute(&request)
    begin
      return request.call
    rescue RestClient::Unauthorized
      @session_id = get_session_id
      return request.call
    rescue RestClient::Forbidden => e
      puts_error(e)
    rescue RestClient::BadRequest => e
      puts_error(e)
    end
    
    exit!
  end
  
  def puts_error(e)
    puts 'Не удалось выполнить запрос.'
    puts "Метод %s." % e.backtrace[11][/`.*/]
    puts "Код ответа '%s'.\nОтвет сервиса '%s'." % [e.message, e.response]
  end
end
