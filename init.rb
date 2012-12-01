Redmine::Plugin.register :redmine_dashbozu_notifier do
  name 'Redmine Dashbozu Notifier plugin'
  author 'suer'
  description 'Redmine Dashbozu Notifier plugin'
  version '0.0.1'
  url 'https://github.com/suer/redmine_dashbozu_notifier'
  author_url 'http://d.hatena.ne.jp/suer'

  Rails.configuration.to_prepare do
    require_dependency 'dashbozu_hooks'
  end

  settings :partial => 'settings/redmine_dashbozu_notifier',
    :default => {
      :dashbozu_url => "",
    }

end
