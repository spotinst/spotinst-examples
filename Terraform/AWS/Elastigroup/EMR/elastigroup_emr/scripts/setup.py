from setuptools import setup, find_packages

setup(
    name='spotinst',
    version='0.1',
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        'Click',
        'spotinst-sdk2',
        'boto3'
    ],
    entry_points='''
        [console_scripts]
        get-emr=get_emr:cli
    ''',
)