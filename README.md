# nwpai


Create an Opensocial DDEV install.


Here is Claude's take on what needs to be done: https://github.com/rjzaar/nwpai/blob/main/roadmap.md#51-purpose-and-functionality 
1) cinstall.sh is able to set up a dev environment with workflow_assignment installed. This could still be improved by being split into two. one sets up the environment sufficiently. The second does an install of workflow_assignment.

2) workflow_assignment needs improvement. This is something that I will need to work on since I know what the whole thing will look like.
   
3) Workflow_assignment needs to have github actions working so it can be tested fully including behat tests. Anyone can do this. This will be really helpful going forward. This might involve using the commons_template.

4) opensocial-moodle-sso-integration. This is a next level task, but is also straight forward for anyone to work on. Basically create SSO for moodle using the opensocial (drupal) login.

5) There are some things that need cleaning up that I should do. eg opensocial-moodle-sso-integration is using the commons_template, but should be using a fork of the opensocial_template. The opensocial_template is old and needs updating, eg ultimate_cron patch. This is currently integrated into workflow_assignment, but opensocial-moodle-sso-integration doesn't need workflow_assignment.

6) I'm happy to get anyone started on any of these tasks.

Checkout https://github.com/rjzaar/nwpai/blob/main/log.md for the log of work, vision and plans

## License

[![CC0](https://licensebuttons.net/p/zero/1.0/88x31.png)](https://creativecommons.org/publicdomain/zero/1.0/)

This work has been dedicated to the public domain under CC0 1.0 Universal. To the extent possible under law, all copyright and related rights have been waived.
