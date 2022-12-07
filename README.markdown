[![Dependency Status](https://gemnasium.com/fernandokosh/redmine_time_tracker.png)](https://gemnasium.com/fernandokosh/redmine_time_tracker) [![Code Climate](https://codeclimate.com/github/fernandokosh/redmine_time_tracker.png)](https://codeclimate.com/github/fernandokosh/redmine_time_tracker)

# Redmine Time Tracker plugin

Time tracker is a Redmine plugin to ease time tracking when working on an issue.
The plugin allows to start/stop a timer on a per user basis. The timer can be started with or without any reference to a Redmine Issue.
If you track multiple timelogs without Issue references, you are able to reference Issues later.

It is be individual configurable for every user and as a module can be enabled per project.

## Features

* Per user time tracking
* Using known Redmine TimeEntries
* Overview of spent time
* Track free time
* Book tracked time on tickets
* Detailed time tracking statistics for team management
* Status monitor, watch currently tracked time of team
* Detailed overview of spent time with filter options (user, project, date)
* Invoice generation for projects, including graphical time representation with customizable company logo
* User specific settings (time tracking on/off)
* Project specific settings (time tracking on/off)
* Admin page (add/remove time logs)

## Getting the plugin

Most current version is available at: [GitHub](https://github.com/fernandokosh/redmine_time_tracker).

## Requirements
* Redmine 2.4.0
* ruby >= 1.8.7 (production, development)
* ruby >= 1.9.2 (test, because of the gem 'timecop', which requires >= 1.9.2)

## Install

1. Follow the Redmine plugin installation steps at http://www.redmine.org/wiki/redmine/Plugins. Make sure the plugin is installed to `#{RAILS_ROOT}/plugins/redmine_time_tracker`
1. Rerun `bundle install` to install all necessary gems
1. Setup the database using the migrations: `rake redmine:plugins:migrate RAILS_ENV=production`
1. Login to your Redmine install as an administrator
1. Setup the "log time" permissions for your roles
1. Enable the "Time tracking" module for your project
1. Activate "Enable REST web service" in the authentication tab in settings
1. Now the link to the plugin should appear in the Main menu bar (upper left corner)

## Update via Git

1. Open a shell to your Redmine's `#{RAILS_ROOT}/plugins/redmine_time_tracker` folder
1. Update your git copy with: `git pull`
1. Update the database using the migrations: `redmine:plugins:migrate RAILS_ENV=production`
1. Restart your Redmine instance

## Usage

To be able to use a time tracker, a user must have the 'log time' permission.
If this is present, the time tracker menu will be visible in the top left menu

To track time on an issue, you can use the context menu (right click in the issues list) in
the issue list to start or stop the timer or press the "Start Tracking" button on the top right, next to the default "Book Time" Redmine button.

## What's what?

The Plugin is intended to help us create invoices for customers. This requires the separation of time that was spent and time that is booked. Only booked times can be billed.
More informations are available in the [wiki](http://github.com/fernandokosh/redmine_time_tracker/wiki "Wiki").

### Time Tracker

The stop watch. Time you spent get's "generated" by the tracker

### Time Log

A time log is a spent amount of time. If you stop the tracker, a time log is created. A time log has nothing attached to it. To add this time to issues or projects, you **book** time.
Role permissions can be edited to disable logging. This might be useful for reviewers, that do not generate time on their own but want to look up statistics on a project or user.

### Time Booking

A booking is time that is actually connected to a task (project or issue). To create a booking, you book time from a time log. You are not limited to spent the whole time of a single booking, you can divide as you wish. You however aren't able book more time than what was actually logged. The role you have on projects and their settings determine if you are able to edit bookings or are just allowed to create them.

### Settings

The plugin offers a list of settings at the Redmine roles and permission settings page. Also you can set the size and file for a logo to be displayed at the report in the Redmine plugin settings, enable rounding behaviour and interval as well as snapping percentage.

### Report

Reports are the method of generating invoices for customers. The layout is set up to be a simple list and you are able to generate a print-out. You can add you custom logo via the plugin settings in the Redmine administration.

## Version History
* 0.9.8 fixed bug, when right-clicking on the time tracker button
* 0.9.7 hide global time tracker button when a user does not have permission to start ’em
* 0.9.6 time tracker now adjusts its start time according to last timelog entry
* 0.9.5 fixed error message shown, when trying to stop a non existant timer
* 0.9.4 fixed critical month name localization bug, fixed test execution, improved reports
* 0.9.3 fixed date queries for time log and time booking
* 0.9.2 fixed compatibility with ruby 1.8.7
* 0.9.1 restored compatibility with ruby 1.8.7
* 0.9.0 compatible with Redmine 2.4.0
* 0.8.3 fixed custom saved query usage
* 0.8.2 fixed missing activity on continue, filters in time recordings now get saved properly
* 0.8.1 bugfix with permission, new setting for default rounding
* 0.8.0 many bugfixes, localized time, new menu buttons, improved workflow
* 0.7.0 compatible with Redmine 2.3.1
* 0.6.2 enhanced error checking of correct settings in Redmine
* 0.6.1 fixed error that resulted in authentication loop using the REST API
* 0.6.0 fixed error with time bookings on ruby 1.8.7
* 0.5.3 fixed routing error
* 0.5.2 fixed error that resulted in reporting plot not being drawn with Ruby 1.8
* 0.5.1 fixed minor bugs to run with Redmine 2.2.0
