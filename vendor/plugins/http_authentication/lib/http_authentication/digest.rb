module HttpAuthentication
  module Digest
    module ControllerMethods
      def authenticate_with_http_digest(&login_procedure)
        HttpAuthentication::Digest.authenticate(self, &login_procedure)
      end

      def request_http_basic_authentication(realm = "Application")
        HttpAuthentication::Digest.authentication_request(self, realm)
      end
    end

    extend self
    
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
      # Fancy nouncing goes here
    end

    def encode_credentials(user_name, password)
      # You compute me
    end

    def authentication_request(controller, realm)
      # Proper headers
      controller.render :text => "Access denied.\n", :status => :unauthorized
      return false    
    end
  end
end