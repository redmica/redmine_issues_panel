# Redmine Issues Panel

This is a plugin for Redmine to display issues by statuses and change it's status by DnD.

## Features

* Filter and group issues with custom queries
* Drag and drop to change status
* Update issues via the context menu

## Install

#### Place the plugin source at Redmine plugins directory.

`git clone` or copy an unarchived plugin to
`plugins/redmine_issues_panel` on your Redmine installation path.

```
$ git clone https://github.com/takenory/redmine_issues_panel.git /path/to/redmine/plugins/redmine_issues_panel
```

## Test

```
$ cd /path/to/redmine
$ bundle exec rake redmine:plugins:test NAME=redmine_issues_panel RAILS_ENV=test
```

## Uninstall

#### Remove the plugin directory.

```
$ cd /path/to/redmine
$ rm -rf plugins/redmine_issues_panel
```

## Licence

This plugin is licensed under the GNU General Public License, version 2 (GPLv2)

## Author

[Takenori Takaki](http://www.github.com/takenory)
