import pytest
import test_config


@pytest.mark.parametrize("parameters", [{"TEST": "1"}])
def test_basic(parameters):
    test_config.run_test(parameters=parameters)
