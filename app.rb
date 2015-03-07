require 'sinatra'
require 'open-uri'
require 'httpclient'
require 'fileutils'
require 'json5'
require 'json'
require 'yaml'
require 'oj'

FIXTURE_PATH = File.dirname(__FILE__) + "/fixtures/"
config = YAML.load_file(File.dirname(__FILE__) + "/config/config.yml")

ORIGIN_URL  = config["origin_url"]  || abort("config: require origin url")
RECORD_PATH = config["record_path"] || "/tmp/stub_record/"
CONTENT_TYPE = config["content_typ"] || "application/json; charset=UTF-8"

# fixture routing
$stdout.sync = true

fixture_config = YAML.load_file(File.dirname(__FILE__) + "/config/fixture.yml")
fixture_config["fixtures"].each{|v|
    get v["route"] do 
       if v["url"] 
          proxy_request(lambda{ HTTPClient.new.get(v["url"]  + "?" + request.query_string,nil,parse_headers(request)) })
          break
       end
       if v["status_code"] 
            status v["status_code"]
       end
       puts "start fixture"
       body = fixture(v["file"])
       puts "end fixture"
       record_response(request,body)
       body
    end
}

definition_config = YAML.load_file(File.dirname(__FILE__) + "/config/definitions.yml")
definition_config["definitions"].each{|c|
    c["fixtures"].each{|v|
        get v["route"] do 
           body = fixture(v["file"])
           record_response(request,body)
           body
        end
    }
}

# stub web
get '/stub' do
    @definitions = definition_config["definitions"]
    @fixtures = fixture_config["fixtures"]
    erb :stub
end

# proxy and recording 

def fixture(file)
    lines =  File.read(FIXTURE_PATH + file + ".json")
    result = erb lines.to_s, :layout => nil 
    content_type CONTENT_TYPE
    if params[:__mode] == "json5"
        result
    else
        json5 = JSON5.parse(result)
        json  = Oj.dump(json5)
        json
    end
end

def parse_headers(request)
    http_headers = request.env.select { |k, v|
                                     k.start_with?('HTTP_') && k != "HTTP_ACCEPT_ENCODING" }
                               .map { |k,v| [ k.gsub(/^HTTP_/,"")
                                    .downcase.gsub(/(^|_)\w/) { |word| word.upcase }
                                    .gsub("_", "-") , v
                                ] }
    return http_headers
end

def filter_header(header)
    filtered = header.select {|k,v| k != "Status" }
    return filtered
end 

def record_request(request)
    begin
        FileUtils.mkdir_p(RECORD_PATH)
        file = RECORD_PATH + request.path_info.gsub("/","_").gsub(/^_/,"") + "?" + request.query_string[0,20];
        log = [
                "ENV:",
                JSON.pretty_generate(request.env),
                "REQUEST:",
                request.request_method + " " + request.url,
                request.body.read ,
        ].join("\n")
    
        File.write(file,log)
        File.open(RECORD_PATH + "all.log","a"){|file|
            file.puts Date.today.strftime("---- DATE: %Y-%m-%d %H:%M:%S --------------")
            file.puts log
        }
    rescue
        puts $!.to_s
    end
end 

def record_response(request,response_body)
    begin
        json_object = JSON.load(response_body)
        FileUtils.mkdir_p(RECORD_PATH)
        file = RECORD_PATH + request.path_info.gsub("/","_").gsub(/^_/,"") + "?" + request.query_string[0,20];
        log = [
                "ENV:",
                JSON.pretty_generate(request.env),
                "REQUEST:",
                request.request_method + " " + request.url,
                request.body.read ,
                "REPONSE:",
                JSON.pretty_generate(json_object)
        ].join("\n")
    
        File.write(file,log)
        File.open(RECORD_PATH + "all.log","a"){|file|
            file.puts Date.today.strftime("---- DATE: %Y-%m-%d %H:%M:%S --------------")
            file.puts log
        }
    rescue
        puts $!.to_s
    end
end 

def proxy_request(f)
    begin
        res = f[]
        headers filter_header(res.header.all)
        record_response(request,res.body)
        body res.content
    rescue
        body $!.to_s
    end
end

get '*' do
    proxy_request(lambda{ HTTPClient.new.get(ORIGIN_URL + request.path_info + "?" + request.query_string,nil,parse_headers(request)) })
end

post '*' do
    proxy_request(lambda{  HTTPClient.new.post(ORIGIN_URL + request.path_info + "?" + request.query_string,request.body,parse_headers(request))})
end

put '*' do
    proxy_request(lambda{ HTTPClient.new.put(ORIGIN_URL + request.path_info + "?" + request.query_string,request.body,parse_headers(request))})
end

delete '*' do
    proxy_request(lambda{ HTTPClient.new.delete(ORIGIN_URL + request.path_info + "?" + request.query_string,parse_headers(request))})
end

patch '*' do
    record_request(request)
    proxy_request(lambda{ HTTPClient.new.patch(ORIGIN_URL + request.path_info + "?" + request.query_string,parse_headers(request))})
end
