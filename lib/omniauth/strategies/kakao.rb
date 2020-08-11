require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Kakao < OmniAuth::Strategies::OAuth2
      DEFAULT_REDIRECT_PATH = "/oauth"

      option :name, 'kakao'

      option :client_options, {
        :site => 'https://kauth.kakao.com',
        :authorize_path => '/oauth/authorize',
        :token_url => '/oauth/token',
      }

      uid { raw_info['id'].to_s }

      info do
        {
          'name' => raw_profile['nickname'],
          'image' => raw_profile['thumbnail_image_url'],
        }
      end

      extra do
        {'properties' => raw_profile}
      end

      def initialize(app, *args, &block)
        super
        options[:callback_path] = options[:redirect_path] || DEFAULT_REDIRECT_PATH
      end

      def callback_url
        options[:callback_url] || (full_host + script_name + callback_path)
      end

      def callback_phase
        previous_callback_path = options.delete(:callback_path)
        @env["PATH_INFO"] = callback_path
        options[:callback_path] = previous_callback_path
        super
      end

      def mock_call!(*)
        options.delete(:callback_path)
        super
      end

    private
      def raw_info
        # {
        #   "id": 10000,
        #   "connected_at": "2015-09-22T00:25:11Z",
        #   "properties": {
        #     "nickname": "홍길동"
        #   },
        #   "kakao_account": {
        #     "profile_needs_agreement": false,
        #     "profile": {
        #       "nickname": "홍길동",
        #       "thumbnail_image_url": "http://image.com",
        #       "profile_image_url": "http://image.com"
        #     }
        #   }
        # }
        @raw_info ||= access_token.get('https://kapi.kakao.com/v2/user/me', {}).parsed || {}
      end

      def kakao_account
        @kakao_account ||= raw_info['kakao_account'] || {}
      end

      def raw_profile
        @raw_profile ||= kakao_account['profile'] || {}
      end
    end
  end
end

OmniAuth.config.add_camelization 'kakao', 'Kakao'
