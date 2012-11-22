# WARNING:

**This Plugin is in full development and therefore should NOT be considered stable or complete in any way. Do not expect any support until the anouncement of a stable release**

(current version works on redmine-trunk (Revision 10864) only!)

# Redmine Time Tracker plugin

Time tracker is a Redmine plugin to ease time tracking when working on an issue.
The plugin allows to start/stop a timer on a per user basis. The timer can be started with or without any reference to a Redmine Issue.
If you track multiple timelogs without Issue references, you are able to reference Issues later.

It will be individual adjustable for every user and seperate includable for any project.

## Features

* Per user time tracking
* Using known Redmine TimeEntries
* Overview of spent Time
* Track free time
* Book tracked time on tickets
* Detailed time tracking statistics for team management
* Status monitor, watch currently tracked time of team
* Detailed overview of spent time with filter options on (user, project, date)
* Invoice generation on project basis including graphical time representation with customizabel company logo
* User specific settings (bookable hours per day, timetracking on/off)
* Project specific settings (timetracking on/off)
* Admin page (setup users bookable hours limit, add/remove timelogs)

## Getting the plugin

Most current version is available at: [GitHub](https://github.com/hicknhack-software/redmine_time_tracker).

## Install

1. Follow the Redmine plugin installation steps at http://www.redmine.org/wiki/redmine/Plugins Make sure the plugin is installed to `#{RAILS_ROOT}/plugins/redmine_time_tracker`
2. Setup the database using the migrations. `rake db:migrate_plugins RAILS_ENV=production`
3. Login to your Redmine install as an Administrator
4. Setup the "log time" permissions for your roles
5. Add "Time tracking" to the enabled modules for your project
6. The link to the plugin should appear in the Main menu bar (upper left corner)

## Update via Git

1. Open a shell to your Redmine's `#{RAILS_ROOT}/plugins/redmine_time_tracker` folder
2. Update your git copy with `git pull`
3. Update the database using the migrations. `rake db:migrate_plugins RAILS_ENV=production`
4. Restart your Redmine

## Usage

To be able to use a time tracker, a user must have the 'log time' permission.
Then, the time tracker menu will appear in the top left menu

To track time referring an issue, you can use the context menu (right click in the issues list) in
the issue list to start or stop the timer.

