import click
import json

from spotinst_sdk2 import SpotinstSession


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
    """Create a new Spot Account"""
    result = ctx.obj['client'].create_account(kwargs.get('name'))
    click.echo(json.dumps(result))


@cli.command()
@click.argument('account-id')
@click.pass_context
def delete(ctx, *args, **kwargs):
    """Delete a Spot Account"""
    ctx.obj['client'].delete_account(kwargs.get('account_id'))


@cli.command()
@click.argument('account-id')
@click.pass_context
def create_external_id(ctx, *args, **kwargs):
    """Generate the Spot External ID for Spot Account connection"""
    ctx.obj['client'].account_id = kwargs.get('account_id')
    result = ctx.obj['client'].create_aws_external_id()
    click.echo(json.dumps(result))


@cli.command()
@click.argument('account-id')
@click.argument('role-arn')
@click.pass_context
def set_cloud_credentials(ctx, *args, **kwargs):
    """Set AWS ROLE ARN to Spot Account"""
    ctx.obj['client'].account_id = kwargs.get('account_id')
    result = ctx.obj['client'].set_cloud_credentials(iam_role=kwargs.get('role_arn'))
    click.echo(json.dumps(result))


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
    """Returns ONLY the first match"""
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