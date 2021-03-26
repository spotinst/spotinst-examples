import click
import json
import logging

from spotinst_sdk2 import SpotinstSession
from spotinst_sdk2.models.elastigroup.aws import *

@click.group()
@click.pass_context
def cli(ctx, *args, **kwargs):
    ctx.obj = {}
    session = SpotinstSession()
    ctx.obj['client'] = session.client("elastigroup_aws")

@cli.command()
@click.pass_context
def get(ctx, *args, **kwargs):
    '''Get List of All Elastigroups Ex: get'''
    result = ctx.obj['client'].get_elastigroups()
    for x in result:
        click.echo(x["id"] + " - " + x["name"])


@cli.command(context_settings=dict(max_content_width=180))
@click.argument('group_id')
@click.option(
    '--batch_percentage',
    '-b',
    type=int,
    default=10,
    show_default=True,
    required=True,
    help='Indicates (in percentage) the batch size of the deployment (meaning, how many instances to replace in each batch).'
)
@click.option(
    '--ami-id',
    '-a',
    type=str,
    required=False,
    help='AMI ID to update the Elastigroup before the roll.'
)
@click.option(
    '--grace_period',
    '-g',
    type=int,
    default=300,
    show_default=True,
    required=True,
    help='Indicates (in seconds) the timeout to wait until instance become healthy based on the healthCheckType.'
)
@click.option(
    '--health_check',
    '-h',
    type=str,
    required=False,
    help='Define a health check type. If no value is set the roll will use the group’s auto-healing health check. Enum: "ELB" "ECS_CLUSTER_INSTANCE" "TARGET_GROUP" "OPSWORKS" "NOMAD_NODE" "MULTAI_TARGET_SET" "HCS" "EC2" "NONE"'
)
@click.pass_context
def roll(ctx, *args, **kwargs):
    '''Roll an elastigroup'''
    if kwargs.get('ami-id'):
        print("made it")
        launchspecification = LaunchSpecification(image_id = kwargs.get('ami-id'))
        compute = Compute(launchspecification)
        update_ami = Elastigroup(compute=compute)
        update = ctx.obj['client'].update_elastigroup(group_update=update_ami, group_id = kwargs.get('group_id'))

    onfailure = OnFailure(action_type="DETACH_NEW")
    rollstategy = RollStrategy(action = "REPLACE_SERVER", on_failure = onfailure)
    if kwargs.get('health_check'):
        roll = Roll(batch_size_percentage = kwargs.get('batch_percentage'), grace_period = kwargs.get('grace_period'), health_check_type = str(kwargs.get('health_check')), strategy = rollstategy)
    else:
        roll = Roll(batch_size_percentage = kwargs.get('batch_percentage'), grace_period = kwargs.get('grace_period'), strategy = rollstategy)
    response = ctx.obj['client'].roll_group(group_id = kwargs.get('group_id'), group_roll = roll)
    click.echo(response)

if __name__ == "__main__":
    cli()