require 'base64'

module HttpAuthentication
  module Basic
    extend self

    module ControllerMethods
      def authenticate_or_request_with_http_basic(realm = "Application", &login_procedure)
        authenticate_with_http_basic(&login_procedure) || request_http_basic_authentication(realm)
      end

      def authenticate_with_http_basic(&login_procedure)
        HttpAuthentication::Basic.authenticate(self, &login_procedure)
      end

      def request_http_basic_authentication(realm = "Application")
        HttpAuthentication::Basic.authentication_request(self, realm)
      end
    end

    def authenticate(controller, &login_procedure)
      if authorization(controller.request)
        login_procedure.call(*user_name_and_password(controller.request))
      else
        false
      end
    end

    def user_name_and_password(request)
      decode_credentials(request).split(/:/, 2)
    end
  
    def authorization(request)
      request.env['HTTP_AUTHORIZATION']   ||
      request.env['X-HTTP_AUTHORIZATION'] ||
      request.env['X_HTTP_AUTHORIZATION']
    end
    
    def decode_credentials(request)
      Base64.decode64(authorization(request).split.last)
    end

    def encode_credentials(user_name, password)
      "Basic #{Base64.encode64("#{user_name}:#{password}")}"
    end

    def authentication_request(controller, realm)
      controller.headers["WWW-Authenticate"] = %(Basic realm="#{realm.gsub(/"/, "")}")
      controller.render :text => "HTTP Basic: Access denied.\n", :status => :unauthorized
      return false    
    end
  end
end