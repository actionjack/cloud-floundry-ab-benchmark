# AB benchmark and plotting

Small script to execute a apache benchmark `ab` from one host to other.

The scripts are designed to benchmark the [Cloud Foundry gorouter](https://github.com/cloudfoundry/gorouter) with two scenarios:

* Increasing load to the base url (/) of a sample [application](https://github.com/alphagov/cf-example-ruby-sinatra)
* Increasing load to and endpoint that gives a delayed response of a second (/sleep/1000) to the sample [application](https://github.com/alphagov/cf-example-ruby-sinatra)

It will gather metrics of request time in the target so they can be later plot using gnuplot.

The ab test results are located in the tests/suite-$TEST/$TOTAL_REQS-conc-$CONCURRENT_REQUESTS directories.

The aggregate graphs are:

![](tests/suite-root-url-test/aggregate.jpg)

The above test started failing after 2500 concurrent connections were reached.

![](tests/suite-1000-millis-sleep-test/aggregate.jpg)

There are corresponding graphs in the tests/suite-$TEST/graphs directory:

System load
CPU DEA Load Average
CF Router requests/responses


## Requirements

### Software in the remote hosts

You must install:

 * `ab` in the source host to execute the test: `ssh -l ubuntu $SOURCE_HOST sudo apt-get install apache2-utils`

### Configuration changes

You need to increase the files open limit on the $SOURCE_HOST:

```
cat <<'EOF' | sudo tee  /etc/security/limits.d/files.conf
* soft nofile 40000
* hard nofile 40000
EOF
```

### Target app

I used the [cf-example-ruby-sinatra application](https://github.com/alphagov/cf-example-ruby-sinatra) for the test suite.

```
cf api --skip-ssl-validation https://api.$DEPLOY_ENV.cf2.paas.alphagov.co.uk
cf login -u user -p password
cd /tmp/
git clone git@github.com:alphagov/cf-example-ruby-sinatra.git
cd cf-example-ruby-sinatra

# And deploy the app
cf push

```

We scale this app to 6-8 units (containers) so we are sure that the backend
is not the bottleneck.

```
cf scale -i 6 cf-example-ruby-sinatra
```

### Example run

#### Gather metrics

The script is setup using environment variables, where the mandatory ones are:

 * `DEPLOY_ENV`: your environment
 * `TARGET_HOST`: one or the routers
 * `SOURCE_HOST`: for instance bastion host

Check all the environment variables in `generate_perf_test.sh` for all possible options.

A very minimal run:

```
DEPLOY_ENV=hector270715 \
TARGET_HOST=10.129.0.72 \
SOURCE_HOST=10.129.0.10 \
  ./execute_perf_test.sh
```

#### Example suites/plans

In `test-plan.sh` there are some plans as an example.

#### Generate graphs and markdown

The script `generate-md.sh` will generate graphs from results directories.
