# Redmine Issues Panel

This is a plugin for Redmine to display issues by statuses and change it's status by DnD.

## Features

* Filter and group issues with custom queries
* Drag and drop to change status
* Update issues via the context menu
* Add a new Issue from the panel

## Install

#### Place the plugin source at Redmine plugins directory.

`git clone` or copy an unarchived plugin to
`plugins/redmine_issues_panel` on your Redmine installation path.

```
$ git clone https://github.com/redmica/redmine_issues_panel.git /path/to/redmine/plugins/redmine_issues_panel
```

## How to activate the Issues Panel

#### Check the 'Issues Panel' checkbox on the Project->Settings->Modules and save it.

![How to activate the Issues Panel](images/how_to_activate.png?raw=true "Check the Issues Panel checkbox on the Project->Settings->Modules")

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

[Takenori Takaki (Far End Technologies)](https://www.farend.co.jp)
