require 'credentials_manager'

module Fastlane
  module Actions
    module SharedValues
      LATEST_TESTFLIGHT_BUILD_NUMBER = :LATEST_TESTFLIGHT_BUILD_NUMBER
    end

    class LatestTestflightBuildNumberAction < Action

      def self.run(params)
        require 'spaceship'

        credentials = CredentialsManager::AccountManager.new(user: params[:username])
        Spaceship::Tunes.login(credentials.user, credentials.password)
        Spaceship::Tunes.select_team
        app = Spaceship::Tunes::Application.find(params[:app_identifier])

        version_number = params[:version]
        unless version_number
          # Automatically fetch the latest version in testflight
          if app.build_trains.keys.last
            version_number = app.build_trains.keys.last
          else
            Helper.log.info "You have to specify a new version number: "
            version_number = STDIN.gets.strip
          end
        end

        Helper.log.info "Fetching the latest build number for version #{version_number}"

        train = app.build_trains[version_number]
        build_number = train.builds.map(&:build_version).map(&:to_i).sort.last

        Helper.log.info "Latest upload is build number: #{build_number}"
        Actions.lane_context[SharedValues::LATEST_TESTFLIGHT_BUILD_NUMBER] = build_number
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Fetches most recent build number from TestFlight"
      end

      def self.details
        "Provides a way to have increment_build_number base the incremented value on the latest value in iTunesConnect by looking up the latest version in TestFlight and the latest build number for that version"
      end

      def self.available_options
        user = CredentialsManager::AppfileConfig.try_fetch_value(:itunes_connect_id)
        user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)

        [
          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                       short_option: "-a",
                                       env_name: "FASTLANE_APP_IDENTIFIER",
                                       description: "The bundle identifier of your app",
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)),
          FastlaneCore::ConfigItem.new(key: :username,
                                       short_option: "-u",
                                       env_name: "ITUNESCONNECT_USER",
                                       description: "Your Apple ID Username",
                                       default_value: user),
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: "LATEST_VERSION",
                                       description: "The version number whose latest build number we want",
                                       optional: true)
        ]
      end

      def self.output
        [
          ['LATEST_TESTFLIGHT_BUILD_NUMBER', 'The latest build number of the latest version of the app uploaded to TestFlight']
        ]
      end

      def self.return_value
        "Integer representation of the latest build number uploaded to TestFlight"
      end

      def self.authors
        ["daveanderson"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
