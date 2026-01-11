#!/usr/bin/env python3
import pytest
import sys
import argparse
import os
import importlib.util


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Run pytest with optional specific test cases and configurations."
    )
    parser.add_argument(
        "test",
        nargs="?",
        help="Name of the specific test to run (optional).",
    )
    parser.add_argument(
        "--config",
        "-c",
        nargs="?",
        default=None,
        help="Identifier of the specific configuration to run (optional).",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List all available tests and their configurations.",
    )
    parser.add_argument(
        "--interactive",
        "-i",
        action="store_true",
        help="Launch interactive menu to select tests and configurations.",
    )

    return parser.parse_args()


def is_pytest_xdist_installed():
    """
    Check if pytest-xdist is installed by looking for the 'xdist' plugin.

    Returns:
        bool: True if pytest-xdist is installed, False otherwise.
    """
    try:
        import pytest
        for plugin in pytest.config.pluginmanager.get_plugins():
            if plugin.name == "xdist":
                return True
    except AttributeError:
        # pytest.config might not be accessible in newer pytest versions
        pass
    except Exception:
        pass

    # Alternative method using importlib to check if 'xdist' can be found
    return importlib.util.find_spec("xdist") is not None


class TestCollector:
    """
    Custom pytest plugin to collect test functions and their configurations.
    """

    def __init__(self):
        self.tests = {}

    def pytest_collection_modifyitems(self, session, config, items):
        """
        Hook that is called after collection of test items.

        Args:
            session: The pytest session object.
            config: The pytest config object.
            items: List of collected test items.
        """
        for item in items:
            # Extract the test function name
            # Remove parameterization suffix
            test_name = item.name.split("[")[0]
            # Extract the parameterization identifier if present
            if "[" in item.name and item.name.endswith("]"):
                config_id = item.name.split("[")[1].rstrip("]")
            else:
                config_id = None

            if test_name not in self.tests:
                self.tests[test_name] = []

            if config_id not in self.tests[test_name]:
                self.tests[test_name].append(config_id)


def collect_tests(test_file="test_list.py"):
    """
    Collect all test functions and their configurations from the specified test file.

    Args:
        test_file (str): Path to the test file.

    Returns:
        dict: A dictionary where keys are test function names and values are lists of config_ids.
    """
    if not os.path.exists(test_file):
        print(f"Test file '{test_file}' not found.")
        sys.exit(1)

    # Instantiate the custom collector
    collector = TestCollector()

    # Run pytest programmatically with the custom collector plugin
    # We use pytest's API to collect tests without executing them
    pytest_args = ["--collect-only", test_file]
    # Initialize pytest with the custom plugin
    pytest.main(pytest_args, plugins=[collector])

    return collector.tests


def list_tests(test_file="test_list.py"):
    """List all available tests and their configurations in the specified test file."""
    all_tests = collect_tests(test_file)

    if not all_tests:
        print("No tests found.")
        return {}

    print("Available tests and configurations:")

    for test, configs in all_tests.items():
        print(f"\n{test}:")
        for idx, config in enumerate(configs, start=1):
            config_display = config if config else "No Configuration"
            print(f"  {idx}. {config_display}")

    return all_tests


def test_runner(test_name=None, config_id=None, has_xdist=False):
    """Run pytest with optional specific test case and configuration."""
    pytest_args = [
        "-o", "log_cli=true",
        "--log-format=%(message)s",
        "--cocotbxml=output/test_report.xml"
    ]

    print(f"Running test file: {test_name}")  # Debug print

    if test_name:
        if config_id:
            # Run a specific test with a specific configuration
            pytest_args.append(f"{test_name}[{config_id}]")
        else:
            # Run all configurations of the specific test
            pytest_args.append(f"{test_name}")
    else:
        # Run all tests
        if has_xdist:
            # Automatically determine number of workers
            pytest_args.extend(["-n", "auto"])
        else:
            print("Warning: pytest-xdist not found. Running tests serially.")

        # Run all tests in the specified file
        pytest_args.append("test_list.py")

    # Execute pytest and exit with its return code
    exit_code = pytest.main(pytest_args)
    sys.exit(exit_code)


def interactive_menu(test_file="test_list.py"):
    """Interactive menu to select tests and configurations to run."""
    all_tests = collect_tests(test_file)
    if not all_tests:
        sys.exit(0)

    test_names = list(all_tests.keys())
    print("\nSelect a test to run:")
    for idx, test in enumerate(test_names, start=1):
        print(f"{idx}. {test}")
    print(f"{len(test_names)+1}. All tests")

    while True:
        try:
            test_choice = input(
                "Enter the number of the test to run (or 'all' to run all tests): ").strip()
            if test_choice.lower() == 'all' or test_choice == '':
                selected_test = None
                selected_config = None
                break
            test_num = int(test_choice)
            if 1 <= test_num <= len(test_names):
                selected_test = test_names[test_num - 1]
                break
            elif test_num == len(test_names) + 1:
                selected_test = None
                selected_config = None
                break
            else:
                print(
                    f"Please enter a number between 1 and {len(test_names)+1}, 'all', or press Enter.")
        except ValueError:
            print("Invalid input. Please enter a valid number, 'all', or press Enter.")

    selected_config = None
    if selected_test:
        configs = all_tests[selected_test]
        print(f"\nAvailable configurations for {selected_test}:")
        for idx, config in enumerate(configs, start=1):
            config_display = config if config else "No Configuration"
            print(f"  {idx}. {config_display}")
        print(f"  {len(configs)+1}. All configurations")

        while True:
            try:
                config_choice = input(
                    "Enter the number of the configuration to run (or 'all' to run all configurations): ").strip()
                if config_choice.lower() == 'all' or config_choice == '':
                    selected_config = None
                    break
                config_num = int(config_choice)
                if 1 <= config_num <= len(configs):
                    selected_config = configs[config_num - 1]
                    break
                elif config_num == len(configs) + 1:
                    selected_config = None
                    break
                else:
                    print(
                        f"Please enter a number between 1 and {len(configs)+1}, 'all', or press Enter.")
            except ValueError:
                print(
                    "Invalid input. Please enter a valid number, 'all', or press Enter.")

    # Check if pytest-xdist is installed
    has_xdist = is_pytest_xdist_installed()

    # Run the selected test and configuration
    if selected_test:
        test_runner(test_name=selected_test,
                    config_id=selected_config, has_xdist=has_xdist)
    else:
        test_runner(has_xdist=has_xdist)


def main():
    args = parse_arguments()

    if args.list:
        list_tests()
        sys.exit(0)

    if args.interactive:
        interactive_menu()
        sys.exit(0)

    # Check if pytest-xdist is installed
    has_xdist = is_pytest_xdist_installed()

    if args.test:
        test_runner(test_name=args.test,
                    config_id=args.config, has_xdist=has_xdist)
    else:
        test_runner(has_xdist=has_xdist)


if __name__ == "__main__":
    main()
