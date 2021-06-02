# Elastigroup Update AMI and Roll

This is a cli script that will update an Elastigroup's launchspecification with a new AMI ID. The script can also roll the desired Elastigroup.

## Installation

```bash
pip3 install --upgrade spotinst-sdk2
```

## Authentication

The mechanism in which the sdk looks for credentials is to search through a list of possible locations and stop as soon as it finds credentials. The order in which the sdk searches for credentials is:

1. Passing credentials as parameters to the `SpotinstClient()` constructor.

```python
client = SpotinstClient(auth_token='token', account_id='act-123')
```

2. Fetching the account and token from environment variables under `SPOTINST_ACCOUNT` and `SPOTINST_TOKEN`.

If you choose to not pass your credentials directly you configure a credentials file, this file should be a valid `.yml` file. The default shared credential file location is `~/.spotinst/credentials` and the default profile is `default`.

```yaml
default: #profile
  token: $defaul_spotinst_token
  account: $default_spotinst-account-id
my_profile:
  token: $my_spotinst_token
  account: $my_spotinst-account-id
```

3. You can overwrite the credentials file location and the profile used as parameters in the `SpotinstClient()` constructor.

```python
client = SpotinstClient(credentials_file='/path/to/file', profile='my_profile')
```

4. You can overwrite the credentials file location and the profile used as environment variables `SPOTINST_PROFILE` and/or `SPOTINST_SHARED_CREDENTIALS_FILE`.

5. Fetching from the default location with the default profile.

## Examples to use the cli script:

#### **Get details via help:**
`python3 roll_eg.py --help`

#### **List all EG and their ID:**
`python3 roll_eg.py get`

#### **Update AMI and roll EG:**
`python3 roll_eg.py roll -a ami-e3fdd999 sig-1234567`

## Documentation

For a comprehensive documentation, check out the [API documentation](https://help.spot.io/).

- [Endpoints](docs/endpoints)
- [Classes](docs/classes)
- [Examples](docs/examples)

## Getting Help

We use GitHub issues for tracking bugs and feature requests. Please use these community resources for getting help:

- Ask a question on [Stack Overflow](https://stackoverflow.com/) and tag it with [spotinst-sdk-python](https://stackoverflow.com/questions/tagged/spotinst-sdk-python/).
- Join our Spotinst community on [Slack](http://slack.spot.io/).
- Open an [issue](https://github.com/spotinst/spotinst-sdk-python/issues/new/).

## Community

- [Slack](http://slack.spot.io/)
- [Twitter](https://twitter.com/spot_hq/)

## License

Code is licensed under the [Apache License 2.0](LICENSE). See [NOTICE.md](NOTICE.md) for complete details, including software and third-party licenses and permissions.

