@centos-iso

Feature: Minishift starts with CentOS iso

  Scenario: Minishift can start with CentOS iso
     When Minishift has state "Does Not Exist"
     Then executing "minishift start" succeeds

  Scenario: Minishift VM is using CentOS distribution
     When executing "minishift ssh -- 'cat /etc/*-release'"
     Then stdout should contain "CentOS Linux release"

  Scenario: User deploys, checks out and deletes several applications
    Given Minishift has state "Running"
     When executing "oc new-app https://github.com/openshift/cakephp-ex.git" succeeds
      And executing "oc expose svc/cakephp-ex" succeeds
      And executing "oc set probe dc/cakephp-ex --readiness --get-url=http://:8080/" succeeds
      And service "cakephp-ex" rollout successfully within "1200" seconds
     Then with up to "10" retries with wait period of "500ms" the "body" of HTTP request to "/" of service "cakephp-ex" in namespace "myproject" contains "Welcome to your CakePHP application on OpenShift"
      And with up to "10" retries with wait period of "500ms" the "status code" of HTTP request to "/" of service "cakephp-ex" in namespace "myproject" is equal to "200"
      And executing "oc delete all --all" succeeds

  Scenario: Deleting Minishift
     When executing "minishift delete --force" succeeds
     Then Minishift should have state "Does Not Exist"
