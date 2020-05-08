from setuptools import setup, find_packages

setup(
    name="escapement-sdk",
    version="1.0.0",
    description="Python client SDK, protocol dissector, and compliance test harness for Escapement IEEE 1588-2019 PTP engine",
    author="Aneesh Krishna",
    packages=find_packages(),
    python_requires=">=3.9",
    install_requires=[],
    entry_points={
        "console_scripts": [
            "escapement-cli=escapement_sdk.cli:main",
        ],
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Topic :: System :: Networking",
    ],
)
