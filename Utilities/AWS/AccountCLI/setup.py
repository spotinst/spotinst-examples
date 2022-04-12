from setuptools import setup, find_packages

setup(
    name='spot-account-aws',
    version='0.1',
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        'Click',
        'spotinst-sdk2>=2.1.10'
    ],
    entry_points='''
        [console_scripts]
        spot-account-aws=spot_account_aws:cli
    ''',
)