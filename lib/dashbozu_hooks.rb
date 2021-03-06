
class DashbozuHook < Redmine::Hook::Listener
  include ApplicationHelper
  include IssuesHelper
  include GravatarHelper::PublicMethods
  include ERB::Util
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  def controller_issues_new_after_save(context = {})
    return unless configured?
    issue   = context[:issue]
    request   = context[:request]
    controller = context[:controller]

    message = {
      :id => issue.id.to_s,
      :subject => "(#{l(:dashbozu_notifier_ticket_new)}) [#{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}",
      :description => issue.description,
      :project => issue.project.name,
      :url => controller.issue_url(issue),
      :iconUrl => gravatar_url(issue.author.mail),
      :author => issue.author.name
    }
    post(message.to_json)
  end

  def controller_issues_edit_after_save(context = {})
    return unless configured?
    issue   = context[:issue]
    journal = context[:journal]
    controller = context[:controller]

    message = {
      :id => "#{issue.id}-#{journal.id}",
      :subject => "(#{l(:dashbozu_notifier_ticket_update)}) [#{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}",
      :description => journal_to_text(issue, journal),
      :project => issue.project.name,
      :url => controller.issue_url(issue),
      :iconUrl => gravatar_url(journal.user.mail),
      :author => journal.user.name
    }
    post(message.to_json)
    journal
  end

  private
  def configured?
    not Setting.plugin_redmine_dashbozu_notifier.nil?
  end

  def journal_to_text(issue, journal)
    contents = ''
    if journal.details.any?
      contents << '<ul class="details">'
      details_to_strings(journal.details, true).each do |detail|
        contents << "<li>#{detail.to_s}</li>"
      end
      contents << '</ul>'
    end
    contents << textilizable(journal, :notes)
  end

  def post(json)
    dashbozu_url = Setting.plugin_redmine_dashbozu_notifier[:dashbozu_url]
    return if dashbozu_url.blank?

    dashbozu_url << '/' unless dashbozu_url.ends_with?('/')
    uri = URI.join(dashbozu_url, 'hook/redmine')
    req = Net::HTTP::Post.new(uri.path)
    req.set_form_data({:json => json})
    req["Content-Type"] = 'application/x-www-form-urlencoded'
    begin
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.class == URI::HTTPS
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      Thread.start do
        http.start do |connection|
          connection.request(req)
        end
      end
    rescue Net::HTTPBadResponse => e
      Rails.logger.error "#{e}"
    end
  end

  # disable Application helper's parse links method
  def parse_redmine_links(text, project, obj, attr, only_path, options)
    text
  end
end
