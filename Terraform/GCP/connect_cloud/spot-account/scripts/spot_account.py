import click
import json
import requests
import base64
import re
import os

from spotinst_sdk2 import SpotinstSession

token_val = os.environ.get('SPOTINST_TOKEN')

@click.group()
@click.pass_context
def cli(ctx, *args, **kwargs):
    ctx.obj = {}
    session = SpotinstSession()
    ctx.obj['client'] = session.client("admin")

@cli.command()
@click.argument('name',)
@click.pass_context
def create(ctx, *args, **kwargs):
    '''Create a new Spot Account'''
    result = ctx.obj['client'].create_account(kwargs.get('name'))
    click.echo(json.dumps(result))


@cli.command()
@click.argument('account-id')
@click.pass_context
def delete(ctx, *args, **kwargs):
    '''Delete a Spot Account'''
    ctx.obj['client'].delete_account(kwargs.get('account_id'))


@cli.command()
@click.argument('accountid')
@click.argument('credential')
def set_cloud_credentials(accountid, credential):
    '''Set serviceaccount to a Spot Account'''
    print(accountid)
    temp = json.loads(base64.b64decode(credential))

    headers = {
        'Content-Type' : 'application/json',
        'Authorization': 'Bearer ' + token_val
    }
    url = 'https://api.spotinst.io/gcp/setup/credentials?accountId=' + accountid
    data = { "serviceAccount" : temp}
    print(data)
    response = requests.post(headers = headers, json=data, url=url)
    print(response)

@cli.command()
@click.option(
    '--filter',
    required=False,
    help='Return matching records. Syntax: key=value'
)
@click.option(
    '--attr',
    required=False,
    help='Return only the raw value of a single attribute'
)
@click.pass_context
def get(ctx, *args, **kwargs):
    '''Returns ONLY the first match'''
    ctx.obj['client'].account_id = kwargs.get('account_id')
    result = ctx.obj['client'].get_accounts()
    if kwargs.get('filter'):
        k, v = kwargs.get('filter').split('=')
        result = [x for x in result if x[k] == v]
    if kwargs.get('attr'):
        if result:
            result = result[0].get(kwargs.get('attr'))
            click.echo(result)
    else:
        if result:
            click.echo(json.dumps(result[0]))


if __name__ == "__main__":
    cli()