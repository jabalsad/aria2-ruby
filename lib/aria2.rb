module Aria2
  class Downloader

    require "aria2/version"
    require 'open-uri'
    require 'json'
    require 'base64'
    require 'cgi'
    require 'net/http'

    def initialize(host = 'localhost', port = 6800, token = '')
      @host = host
      @port = port
      @token = token
    end

    def check
      begin
        rpc_call('getGlobalStat')
        true
      rescue
        false
      end
    end

    def remove(gid)
      rpc_call('remove', [gid])
    end

    def force_remove(gid)
      rpc_call('forceRemove', [gid])
    end

    def pause(gid)
      rpc_call('pause', [gid])
    end

    def pause_all
      rpc_call('pauseAll')
    end

    def force_pause(gid)
      rpc_call('forcePause', [gid])
    end

    def force_pause_all
      rpc_call('forcePauseAll')
    end

    def unpause(gid)
      rpc_call('unPause', [gid])
    end

    def unpause_all
      rpc_call('unPauseAll')
    end

    def download(url, path, opts={})
      path = File.expand_path(path)
      rpc_call('addUri', [[url], {
        'dir' => File.dirname(path), 
        'out' => File.basename(path),
        'allow-overwrite' => 'true'
      }.merge(opts)])
    end

    def get_uris(gid) 
      rpc_call('getUris', [gid])
    end

    def get_files(gid)
      rpc_call('getFiles', [gid])
    end

    def get_peers(gid)
      rpc_call('getPeers', [gid])
    end

    def get_servers(gid)
      rpc_call('getServers', [gid])
    end

    def get_option(gid)
      rpc_call('getOption', [gid])
    end

    def purge_download_result
      rpc_call('purgeDownloadResult')
    end

    def remove_download_result(gid)
      rpc_call('removeDownloadResult', [gid])
    end

    def get_version
      rpc_call('getVersion')
    end

    def get_session_info
      rpc_call('getSessionInfo')
    end

    def shutdown
      rpc_call('shutdown')
    end

    def force_shutdown
      rpc_call('forceShutdown')
    end

    def save_session
      rpc_call('saveSession')
    end

    def add_torrent(torrent)
      rpc_call('addTorrent', [torrent])
    end

    def add_torrent_file(filename)
      torrent = Base64.encode64(File.open(filename, "rb").read)
      add_torrent(torrent)
    end

    def get_active
      rpc_call('tellActive')
    end

    def query_status(gid)
      status = rpc_call('tellStatus', [gid, [
        'status', 
        'totalLength', 
        'completedLength', 
        'downloadSpeed', 
        'errorCode'
      ]])

      status['totalLength'] = status['totalLength'].to_i
      status['completedLength'] = status['completedLength'].to_i
      status['downloadSpeed'] = status['downloadSpeed'].to_i
      status['errorCode'] = status['errorCode'].to_i

      status['progress'] = status['totalLength'] == 0 ? 
        0 :
        status['completedLength'].to_f / status['totalLength'].to_f

      status['remainingTime'] = status['downloadSpeed'] == 0 ?
        0 :
        (status['totalLength'] - status['completedLength']).to_f / status['downloadSpeed']

      status
    end

    private

    def get(url, params = {})
      uri = URI.parse(url)

      uri.query = URI.encode_www_form(params)

      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)

      response = http.request(request)

      {
        'code' => response.code.to_i, 
        'body' => response.body
      }
    end

    def rpc_path
      "http://#{@host}:#{@port}/jsonrpc"
    end

    def rpc_call(method, params = [])
      method = "aria2.#{method}"
      id = 'ruby-aria2'
      params_encoded = Base64.encode64(JSON.generate(params))
      if @token != '' then
        response = get("#{self.rpc_path}", {'token' => @token, 'method' => method, 'id' => id, 'params' => params_encoded})
      else
        response = get("#{self.rpc_path}", {'method' => method, 'id' => id, 'params' => params_encoded})
      end
      answer = JSON.parse(response['body'])

      if response['code'] == 200
        answer['result']
      else
        raise "AriaDownloader error #{answer['error']['code'].to_i}: #{answer['error']['message']}"
      end
    end

  end
end

