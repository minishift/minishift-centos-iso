@example

Feature: Minishift starts with CentOS iso

  Scenario: Minishift can start with CentOS iso
     When Minishift has state "Does Not Exist"
     Then executing "minishift start" succeeds

  Scenario: Minishift VM is using CentOS distribution
     When executing "minishift ssh -- 'cat /etc/*-release'"
     Then stdout should contain "CentOS Linux release"

  Scenario Outline: User deploys, checks out and deletes several applications
    Given Minishift has state "Running"
     When executing "oc new-app <template-name>" succeeds
      And executing "oc expose svc/<service-name>" succeeds
      And executing "oc set probe dc/<service-name> --readiness --get-url=http://:8080<http-endpoint>" succeeds
      And service "<service-name>" rollout successfully within "1200" seconds
     Then with up to "10" retries with wait period of "500ms" the "body" of HTTP request to "<http-endpoint>" of service "<service-name>" in namespace "myproject" contains "<expected-hello>"
      And with up to "10" retries with wait period of "500ms" the "status code" of HTTP request to "<http-endpoint>" of service "<service-name>" in namespace "myproject" is equal to "200"
      And executing "oc delete all --all" succeeds

  Examples: Required information to test the templates
    | template-name                               | service-name | http-endpoint | expected-hello                                   |
    | https://github.com/openshift/ruby-ex.git    | ruby-ex      | /             | Welcome to your Ruby application on OpenShift    |
    | https://github.com/openshift/nodejs-ex      | nodejs-ex    | /             | Welcome to your Node.js application on OpenShift |
    | https://github.com/openshift/django-ex.git  | django-ex    | /             | Welcome to your Django application on OpenShift  |
    | https://github.com/openshift/dancer-ex.git  | dancer-ex    | /             | Welcome to your Dancer application on OpenShift  |
    | https://github.com/openshift/cakephp-ex.git | cakephp-ex   | /             | Welcome to your CakePHP application on OpenShift |

  Scenario: Deleting Minishift
     When executing "minishift delete --force" succeeds
     Then Minishift should have state "Does Not Exist"
