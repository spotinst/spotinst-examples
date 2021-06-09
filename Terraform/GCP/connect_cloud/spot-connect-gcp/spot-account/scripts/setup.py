from setuptools import setup, find_packages

setup(
    name='spot',
    version='0.1',
    packages=find_packages(),
    include_package_data=True,
    author="Steven Feltner",
    author_email="steven.feltner@spot.io",
    license="MIT",
    install_requires=[
        "Click",
        "spotinst-sdk2",
        "requests",
    ],
    entry_points='''
        [console_scripts]
        spot-account=spot_account:cli
    ''',
)